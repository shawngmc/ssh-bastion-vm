Am I still running vault?

Option 1 — HashiCorp Vault with a Cubbyhole token (recommended)
The cubbyhole pattern: Proxmox generates a one-time Vault token at VM creation, passes it via Cloud-Init, VM uses it once to pull its secrets, token expires.
On the Proxmox host at VM creation:
bash#!/bin/bash
VMID=$1
USERNAME=sshuser

# 1. Create a short-lived, single-use Vault token
WRAPPED_TOKEN=$(vault token create \
  --policy=vm-bootstrap \
  --ttl=5m \
  --use-limit=2 \
  --wrap-ttl=5m \
  --format=json | jq -r '.wrap_info.token')

# 2. Write VM secrets into Vault ahead of time
vault kv put secret/vms/${VMID}/config \
  pro_token="${UBUNTU_PRO_TOKEN}" \
  ssh_user="${USERNAME}"

# 3. Pass the wrapped token to the VM via Cloud-Init snippet
cat > /var/lib/vz/snippets/vm-${VMID}-bootstrap.yaml << EOF
#cloud-config
write_files:
  - path: /etc/bootstrap-token
    permissions: '0600'
    content: "${WRAPPED_TOKEN}"
runcmd:
  - /usr/local/bin/vm-bootstrap.sh
EOF

qm set ${VMID} --cicustom "user=local:snippets/vm-${VMID}-bootstrap.yaml"
Vault policy (vm-bootstrap):
hcl# Allow the VM to unwrap its token
path "sys/wrapping/unwrap" {
  capabilities = ["update"]
}

# Allow reading its own secrets only
path "secret/data/vms/{{identity.entity.id}}/*" {
  capabilities = ["read"]
}
Bootstrap script inside the VM (/usr/local/bin/vm-bootstrap.sh):
bash#!/bin/bash
set +x  # never trace this script
set -e

VAULT_ADDR="https://vault.your-internal-domain"
VMID=$(cat /etc/machine-id)  # or pass via cloud-init

# 1. Unwrap the token — this consumes it, making it useless to anyone else
VAULT_TOKEN=$(vault unwrap \
  -address=${VAULT_ADDR} \
  -format=json \
  $(cat /etc/bootstrap-token) | jq -r '.auth.client_token')

# 2. Pull secrets
PRO_TOKEN=$(VAULT_TOKEN=${VAULT_TOKEN} vault kv get \
  -address=${VAULT_ADDR} \
  -field=pro_token \
  secret/vms/${VMID}/config)

# 3. Use them
pro attach "${PRO_TOKEN}"

# 4. Clean up — delete token file and revoke the vault token
rm -f /etc/bootstrap-token
VAULT_TOKEN=${VAULT_TOKEN} vault token revoke \
  -address=${VAULT_ADDR} -self

unset VAULT_TOKEN PRO_TOKEN

Option 2 — Vault Agent with AppRole (more robust, more setup)
Better for long-running VMs that need to periodically re-fetch secrets:
bash# On Vault — create an AppRole per VM
vault auth enable approle

vault write auth/approle/role/vm-${VMID} \
  token_policies="vm-${VMID}-policy" \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_num_uses=1 \
  secret_id_ttl=10m

# Get the RoleID (not secret, can be baked into image)
ROLE_ID=$(vault read -field=role_id auth/approle/role/vm-${VMID}/role-id)

# Get a single-use SecretID (this is the secret, passed via cloud-init)
SECRET_ID=$(vault write -field=secret_id -f \
  auth/approle/role/vm-${VMID}/secret-id)
Then Vault Agent runs inside the VM and handles token renewal automatically:
hcl# /etc/vault-agent.hcl
vault {
  address = "https://vault.your-internal-domain"
}

auto_auth {
  method "approle" {
    config = {
      role_id_file_path   = "/etc/vault/role-id"
      secret_id_file_path = "/etc/vault/secret-id"
      remove_secret_id_file_after_reading = true
    }
  }
  sink "file" {
    config = {
      path = "/run/vault-token"
      mode = 0640
    }
  }
}

template {
  source      = "/etc/vault/templates/pro-token.ctmpl"
  destination = "/run/secrets/pro-token"
  perms       = 0640
}

Option 3 — Proxmox + TPM2 (hardware-rooted, most secure)
Proxmox 7.3+ supports virtual TPM2 devices. You can seal secrets to the TPM so they can only be unsealed by that specific VM in a known state:
bash# Add vTPM to VM in Proxmox
qm set <vmid> --tpmstate local:4,version=v2.0

# Inside the VM — seal a secret to the TPM
tpm2_createprimary -C e -c primary.ctx
tpm2_create -C primary.ctx -d secret.bin -u sealed.pub -r sealed.priv
tpm2_load -C primary.ctx -u sealed.pub -r sealed.priv -c sealed.ctx
tpm2_unseal -c sealed.ctx  # only works on this VM