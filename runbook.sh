# 10. Install and Update
apt-get update
apt-get upgrade
apt-get install -y \
  openssh-server \
  fail2ban \
  libpam-pwquality \
  ufw \
  unattended-upgrades \
  libpam-google-authenticator \
  qemu-guest-agent

# 15. Enable Qemu Guest Tools
systemctl enable --now qemu-guest-agent
# Must be enabled in the web UI:
# VM → Options → QEMU Guest Agent → Enable

# 20. Drop in the hardened sshd_config 
cat > /etc/ssh/sshd_config << 'EOF'
# Network
Port 22
AddressFamily inet
ListenAddress 0.0.0.0

# Authentication
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 5
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication yes
UsePAM yes
AuthenticationMethods publickey,keyboard-interactive

# Key exchange & ciphers (modern, hardened)
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Privilege separation & sandboxing
UsePrivilegeSeparation sandbox

# Session hardening
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive no

# Disable legacy/risky features
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
GatewayPorts no
PermitUserEnvironment no
PrintMotd no
Banner /etc/ssh/banner

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Host Keys
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
EOF

# 30. Regenerate host keys (ed25519 + rsa-4096 only)
rm -f /etc/ssh/ssh_host_*_key*
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""

# 40. TODO: Stage the authorized_keys file

# 45. Generate TOTP secret for user
USERNAME=sshuser

# Run as the target user, not root
sudo -u ${USERNAME} google-authenticator \
  --time-based \
  --force \
  --disallow-reuse \
  --rate-limit=3 \
  --rate-time=30 \
  --window-size=3 \
  --no-confirm \
  --qr-mode=UTF8 \
  --secret=/home/${USERNAME}/.google_authenticator

# Fix ownership and permissions
chmod 400 /home/${USERNAME}/.google_authenticator
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.google_authenticator

# TODO: give the user the TOTP key in /home/${USERNAME}/.google_authenticator without catting to logs

# 50. Set banner file
echo "Authorized access only. All activity is monitored and logged." > /etc/ssh/banner

# 55. Configure PAM for Google Authenticator
# Edit /etc/pam.d/sshd — add nullok initially so existing users aren't locked out
# Remove nullok once all users have enrolled
cat >> /etc/pam.d/sshd << 'EOF'

# Google Authenticator TOTP (add nullok during enrollment, remove after)
auth required pam_google_authenticator.so nullok
EOF

# 60. Configure fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled  = true
port     = ssh
maxretry = 3
bantime  = 3600
findtime = 600
EOF

# 70. UFW — only allow SSH
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# 80. Enable and start
systemctl enable --now ssh fail2ban
systemctl restart ssh

# 90. Attach Pro subscription
# TODO: Get UBUNTU_PRO_TOKEN
pro attach $UBUNTU_PRO_TOKEN
# Enable livepatch via Pro
pro enable livepatch
# Check status
pro status

# 100. Enable automatic updates
# See https://ubuntu.com/server/docs/how-to/software/automatic-updates/
# Configure reboots intelligently
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
// Enable security updates
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

// Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Don't reboot automatically — livepatch handles kernel patching live
Unattended-Upgrade::Automatic-Reboot "false";

// If you do want reboots (e.g. for glibc updates that need it), 
// schedule them for a maintenance window instead:
// Unattended-Upgrade::Automatic-Reboot "true";
// Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Email alerts on failures (optional but recommended)
// TODO: Need an MTA for this
//Unattended-Upgrade::Mail "shawngmc@gmail.com";
//Unattended-Upgrade::MailReport "on-change";
EOF
systemctl enable --now unattended-upgrades
