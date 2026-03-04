Authentication & Access

Hardware keys (FIDO2/passkeys) — OpenSSH 8.2+ supports sk-ed25519 keys (YubiKey, etc.). Requires physical touch to authenticate, defeats stolen key files entirely.
Restrict allowed users — add AllowUsers youruser or AllowGroups sshusers to sshd_config. Explicit allowlist beats relying on account hardening alone.
Port knocking or Single Packet Authorization (SPA) — fwknop implements SPA, which keeps port 22 completely invisible (DROP, not REJECT) until a valid encrypted knock arrives. Eliminates exposure to automated scanners entirely.


Network Layer

VPN-only access — put SSH behind WireGuard or Tailscale. Port 22 is never exposed to the public internet at all. Strongest network-layer option.
Separate VLAN — isolate the VM on its own Proxmox bridge/VLAN so a compromise can't pivot to other VMs.


Host Intrusion Detection

AIDE or Tripwire — filesystem integrity monitoring. Detects if binaries, configs, or cron jobs are modified post-compromise.
auditd — kernel-level syscall auditing. Logs execve, file opens, privilege escalations. Essential for forensics.
osquery — SQL-queryable host telemetry. Good for continuous compliance checks ("are SSH keys as expected?").
Wazuh or OSSEC — full HIDS combining log analysis, file integrity, and active response. Wazuh also ships a SIEM if you want centralized visibility across VMs.


OS Hardening

Unattended upgrades — apt-get install unattended-upgrades + enable security updates. Patches land without manual intervention.
AppArmor profile for sshd — Ubuntu ships one by default; verify it's enforcing with aa-status. Constrains what sshd can access even if exploited.
Disable unused services — systemctl list-units --type=service --state=running and disable everything not needed.
Kernel hardening via sysctl:

bash# /etc/sysctl.d/99-harden.conf
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.tcp_syncookies = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

Remove compilers and dev tools — apt-get remove gcc g++ make perl reduces post-compromise capability significantly.


Secrets & Key Management

Rotate host keys periodically — especially after any suspected compromise or personnel change.
Audit authorized_keys regularly — stale keys from former users are a common, silent entry point.
ssh-audit — run ssh-audit <host> against your server to get a graded report of your cipher/key/config posture. Good to run after any config change.


Monitoring & Alerting

Centralized logging — ship auth.log to a remote syslog or SIEM (Loki, Graylog, Splunk) so logs survive a compromise of the VM.
Alert on: successful root login (should never happen), logins from new IPs, logins outside business hours, multiple fail2ban bans in a short window.
Proxmox snapshots on a schedule — automated pre/post-patch snapshots give you a forensic baseline and fast recovery.


The highest-leverage combination for most use cases is: VPN-only access (WireGuard/Tailscale) + FIDO2 hardware keys + unattended-upgrades + auditd + centralized log shipping. That eliminates internet exposure entirely, requires physical hardware to authenticate, and ensures you have tamper-evident logs even if the VM is compromised.





SKIP
- Non-standard port - LARGELY POINTLESS - minor deterrent, but dramatically reduces log noise from automated scanners. Not security by obscurity on its own, but useful in combination.
- Proxmox datacenter firewall - REQUIRES BIGGER INSTANCE - enforce an IP allowlist at the hypervisor level, independent of the VM. Even if the VM's ufw is misconfigured, the outer firewall holds.
- Short-lived certificates instead of static keys - OVERKILL - use OpenSSH CA (ssh-keygen -s) or HashiCorp Vault SSH secrets engine to issue certs that expire in hours. Eliminates the "forgotten authorized_keys" problem entirely.
