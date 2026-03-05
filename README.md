## Architecture
- VM on proxmox
- Custom cloud-init user-data.yaml for startup control
- Mount start scripts and secrets in VirtIOFS

## Setup
Ensure you have the prereqs done!

### Setup reusable vars
```
# Adjust these!
ROLE_SLUG=ssh-bastion
TEMPLATEID=103
VMID=102
VMMAC=BC:24:11:C5:A5:92
VMIP=192.168.1.25
```

### Create the directory mapping (one-time)
```
mkdir -pv "/var/lib/vz/virtiofs/${ROLE_SLUG}/"

# Add the directory mapping to the host
pvesh create /cluster/mapping/dir --id "${ROLE_SLUG}-virtiofs" --map node=$(hostname),path=/var/lib/vz/virtiofs/${ROLE_SLUG}/
```

### Stage the source
```
cd "/var/lib/vz/virtiofs/${ROLE_SLUG}/"
cat {"foo": "bar"} > config.json
wget https://github.com/shawngmc/ssh-bastion-vm/archive/refs/heads/main.zip
unzip main.zip
rm -rf main.zip
mv ssh-bastion-vm-main/* ./
rm -rf ssh-bastion-vm-main/
cp user-data.yaml /var/lib/vz/snippets/${ROLE_SLUG}-user-data.yaml

# TODO: Stage custom config here!
cp /var/lib/vz/virtiofs/ssh-bastion-config.json /var/lib/vz/virtiofs/ssh-bastion/config.json
```

### VirtIOFS and Set User Data
```
# Clone the template
qm clone ${TEMPLATEID} ${VMID} --name ${ROLE_SLUG}

# Set the MAC
qm set ${VMID} -net0 virtio=${VMMAC},bridge=vmbr0

# Add the FS to the VM:
qm set "${VMID}" --virtiofs0 "${ROLE_SLUG}-virtiofs"

# Set the custom cloud-init
qm set "${VMID}" --cicustom "user=local:snippets/${ROLE_SLUG}-user-data.yaml"

qm start "${VMID}"
```

### Rotation
```
qm stop ${VMID}
qm destroy ${VMID}
```

## Prereqs

### Enable Snippets on Proxmox
In proxmox shell:
```
mkdir -pv "/var/lib/vz/snippets/"
```
In WebUI:
- Go to Datacenter -> Storage -> Add -> Directory.
- ID: Name it (e.g., snippets).
- Directory: Enter the path (e.g., /var/lib/vz/snippets).
- Content: Select Snippets.

## Making the base Ubuntu VM
Ref https://www.youtube.com/watch?v=dSLRYIFMBfo

In WebUI:
1. Create VM
1. In General, give it the name you want the template to have
1. In OS, Do not use any media
1. In system, check TPM (store on local-lvm) and QEMU Agent, BIOS to UEFI
1. In disks, remove built-in
1. In CPU, choose 'host' type.
1. Finish creation, but do not start.


In shell:
```
cd /var/lib/vz
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
qm importdisk 103 noble-server-cloudimg-amd64.img local-lvm
```
Back in WebUI:
1. In Hardware, select Unused Disk, then choose Edit. 
1. Set to discard on SSD backend, then click Add.
1. Add a cloud-init drive, ensuring that it uses SATA.
1. In Cloud-init, set IP Config to DHCP.
1. In Options, change the Boot Order to just be the new disk.
1. In top-right, More, Convert to Template



## TODO
- Split out config files and use envsubst to inject env vars ```envsubst '$var1,$var2" < template.txt > output.txt```
- Break down sec improvements
- Cleanup
