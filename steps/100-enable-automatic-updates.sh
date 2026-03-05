#!/usr/bin/env bash
set -euo pipefail

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
// Enable security updates
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

// Remove unused dependencies
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Don't reboot automatically — livepatch handles kernel patching live
Unattended-Upgrade::Automatic-Reboot "false";

// If you do want reboots (e.g. for glibc updates that need it),
// schedule them for a maintenance window instead:
// Unattended-Upgrade::Automatic-Reboot "true";
// Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Email alerts on failures (optional but recommended)
// TODO: Need an MTA for this
Unattended-Upgrade::Mail "shawngmc@gmail.com";
Unattended-Upgrade::MailReport "on-change";
EOF
systemctl enable --now unattended-upgrades
