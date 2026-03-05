## Architecture
- VM on proxmox
- Custom cloud-init user-data.yaml for startup control
- Mount start scripts and secrets in VirtIOFS

## Setup
### Enable Snippets on Proxmox
In proxmox shell:
```
mkdir -pv "/var/lib/vz/snippets/"
```
In WebUI:
- Go to Datacenter -> Storage -> Add -> Directory.
- ID: Name it (e.g., snippets).
- Directory: Enter the path (e.g., /var/lib/vz/snippets).
- Content: Select Snippets.


### Create the VM

### VirtIOFS and Set User Data
In proxmox shell:
```
# Adjust these!
ROLE_SLUG=ssh-bastion
VMID=102

# Set up path dir
mkdir -pv "/var/lib/vz/virtiofs/${ROLE_SLUG}/"
cd "/var/lib/vz/virtiofs/${ROLE_SLUG}/"
cat {"foo": "bar"} > config.json
wget https://github.com/shawngmc/ssh-bastion-vm/archive/refs/heads/main.zip
unzip main.zip
cp user-data.yaml /var/lib/vz/snippets/${ROLE_SLUG}-user-data.yaml

# TODO: Stage custom config here!

# Add the directory mapping to the host
pvesh create /cluster/mapping/dir --id "${ROLE_SLUG}-virtiofs" --map node=$(hostname),path=/var/lib/vz/virtiofs/${ROLE_SLUG}/

pvesh create /datacenter/directory-mappings --name "${ROLE_SLUG}-virtiofs" --path /var/lib/vz/virtiofs/${ROLE_SLUG}/ --node $(hostname)
# Add the FS to the node:
qm set "${VMID}"--virtiofs0 "${ROLE_SLUG}-virtiofs"


qm set "${VMID}"  --cicustom "user=local:snippets/${ROLE_SLUG}-user-data.yaml"
```
  
### Mount in instance
1. Create mount point: mkdir -p /mnt/<mntpoint
1. Mount: mount -t virtiofs <tag> /mnt/<mntpoint.cd ss
1. Add to /etc/fstab for persistence: <tag> /mnt/<mntpoint> virtiofs defaults,nofail 0 0. Add an empty line to prevent warnings.
```
# Create mount point
mkdir -p /mnt/config
# Mount
mount -t virtiofs ssh-bastion-virtiofs /mnt/config
# Add to /etc/fstab for persistence: 
echo "ssh-bastion-virtiofs /mnt/config virtiofs defaults,nofail 0 0" | sudo tee -a "/etc/fstab" > /dev/null
# Add an empty newline at the end of fstab to avoid warnings
echo "" | sudo tee -a "/etc/fstab" > /dev/null


## Making the base Ubuntu VM
Ref https://www.youtube.com/watch?v=dSLRYIFMBfo
In WebUI:
1. Create VM
1. In General, give it the name you want the template to have
1. In OS, Do not use any media
1. In system, check TPM (store on local-lvm) and QEMU Agent, BIOS to UEFI
1. In disks, remove built-in
1. In CPU, choose 'host' type.
1. Finish creation, but do not start.


In shell:
```
cd /var/lib/vz
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
qm importdisk 103 noble-server-cloudimg-amd64.img local-lvm
```
Back in WebUI:
1. In Hardware, select Unused Disk, then choose Edit. 
1. Set to discard on SSD backend, then click Add.
1. Add a cloud-init drive, ensuring that it uses SATA.
1. In Cloud-init, set IP Config to DHCP.
1. In Options, change the Boot Order to just be the new disk.
1. In top-right, More, Convert to Template



## TODO
- Split out config files and use envsubst to inject env vars ```envsubst < template.txt > output.txt```
- Break down sec improvements
- Cleanup
