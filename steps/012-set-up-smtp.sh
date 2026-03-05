#!/usr/bin/env bash
set -euo pipefail

EMAIL=$(jq -r .email /mnt/config/config.json)
cat >/etc/ssmtp/ssmtp.conf << EOF
bash
root=${EMAIL}
mailhub=smtp.gmail.com:587
hostname=smtp.gmail.com
UseTLS=YES
UseSTARTTLS=YES
AuthUser=${EMAIL}
AuthPass=$(jq -r .gmailapppassword /mnt/config/config.json)
FromLineOverride=YES
EOF
SLUG=$(jq -r .slug /mnt/config/config.json)
echo "Hello World" | mail -s "Test Email from new Proxmox vm ${SLUG}" shawngmc@gmail.com
