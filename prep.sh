#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="${SCRIPT_DIR}/steps"

for step_script in "${STEPS_DIR}"/*.sh; do
  echo "==> Running $(basename "${step_script}")"
  bash "${step_script}"
done
