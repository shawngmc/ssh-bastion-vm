#!/usr/bin/env bash
set -euo pipefail

USERNAME=$(jq -r .username /mnt/config/config.json)

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

chmod 400 /home/${USERNAME}/.google_authenticator
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.google_authenticator

SLUG=$(jq -r .slug /mnt/config/config.json)
EMAIL=$(jq -r .email /mnt/config/config.json)
echo "TOTP Key: $(cat /home/${USERNAME}/.google_authenticator)" | mail -s "TOTP Key from new proxmox VM ${SLUG}" ${EMAIL}
