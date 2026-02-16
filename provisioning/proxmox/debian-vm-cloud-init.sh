# Download the genericcloud image
wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2

# Create the VM
VMID=200
qm create $VMID --name debian13 --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the cloud-init disk to storage - local storage here
qm importdisk $VMID debian-13-genericcloud-amd64.qcow2 local
qm set $VMID --scsihw virtio-scsi-pci --scsi0 local:${VMID}/vm-${VMID}-disk-0.raw,discard=on,ssd=1

# Set boot order and add the cloud-init drive
qm set $VMID --boot order=scsi0
qm set $VMID --ide2 local:cloudinit

# Enable serial console + QEMU guest agent
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent enabled=1
qm set $VMID -cpu host  # Pass through all CPU flags

# Configure cloud-init
qm set $VMID --ciuser $USER
qm set $VMID --sshkeys ~/.ssh/authorized_keys
qm set $VMID --ipconfig0 ip=dhcp

# Resize the disk — cloud image ships with ~3GB
qm resize $VMID scsi0 +30G

# Optional - make a template
qm template $VMID

# Boot
qm start $VMID