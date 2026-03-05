#!/usr/bin/env bash
set -euo pipefail

systemctl enable --now qemu-guest-agent
