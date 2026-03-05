#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y \
  openssh-server \
  fail2ban \
  libpam-pwquality \
  ufw \
  unattended-upgrades \
  libpam-google-authenticator \
  qemu-guest-agent \
  jq \
  ssmtp
