#!/usr/bin/env bash
set -euo pipefail

UBUNTU_PRO_TOKEN=$(jq -r .ubuntupro /mnt/config/config.json)
pro attach $UBUNTU_PRO_TOKEN
pro status
