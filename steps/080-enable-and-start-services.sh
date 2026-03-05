#!/usr/bin/env bash
set -euo pipefail

systemctl enable --now ssh fail2ban
systemctl restart ssh
