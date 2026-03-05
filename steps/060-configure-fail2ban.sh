#!/usr/bin/env bash
set -euo pipefail

cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled  = true
port     = ssh
maxretry = 3
bantime  = 3600
findtime = 600
EOF

systemctl enable --now fail2ban