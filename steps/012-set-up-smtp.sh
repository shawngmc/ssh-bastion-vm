#!/usr/bin/env bash
set -euo pipefail

cat >/etc/ssmtp/ssmtp.conf << 'EOF'
bash
root=shawngmc@gmail.com
mailhub=smtp.gmail.com:587
hostname=smtp.gmail.com
UseTLS=YES
UseSTARTTLS=YES
AuthUser=shawngmc@gmail.com
AuthPass=$(jq -r .gmailapppassword /mnt/config/config.json)
FromLineOverride=YES
EOF
SLUG=$(jq -r .slug /mnt/config/config.json)
echo "Hello World" | mail -s "Test Email from new Proxmox vm ${SLUG}" shawngmc@gmail.com
