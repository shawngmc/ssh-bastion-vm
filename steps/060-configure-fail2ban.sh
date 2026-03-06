#!/usr/bin/env bash
set -euo pipefail

cp ../templates/fail2ban/jail.local /etc/fail2ban/jail.local
export EMAIL=$(jq -r .email /mnt/config/config.json)
envsubst '$EMAIL' < ../templates/fail2ban/mail-on-ban.conf > /etc/fail2ban/action.d/mail-on-ban.conf

systemctl enable --now fail2ban