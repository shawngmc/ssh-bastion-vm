#!/usr/bin/env bash
set -euo pipefail

cat >> /etc/pam.d/sshd << 'EOF'

# Google Authenticator TOTP (add nullok during enrollment, remove after)
auth required pam_google_authenticator.so nullok
EOF
