#!/bin/bash 
set -eo pipefail

# PREP: 
# arch: pacman -S libvirt qemu ebtables dmidecode libguestfs virt-install cpio cloud-utils edk2-ovmf


# --> Setup environment
source ./settings.conf
NOW=$(date +"%Y-%m-%d")

# --> Parse arguments: 
if [ -z $1 ]; then 
    echo "Command help: "
    exit 1
fi

while [[ "$#" -gt 0 ]]; do 
case $1 in 
    -c|--cpus) CPUS=$2 ;;
    -m|--mem ) MEM=$2 ;;
    -d|--disk) DISK=$2 ;;
    -i|--net ) NET=$2 ;;
    -o|--os  ) OS=$2 ;;
    -n|--name) NAME=$2;;
    *);;
esac
shift
done; 

echo -e "System Parameters:\n -> cpus=$CPUS\n -> mem=$MEM \n -> disk=$DISK \n -> net=$NET \n -> os=$OS \n -> name=$NAME"

# Expand the path
BASEPATH=$(readlink --canonicalize ~/virt)

# Check if image exists, and download if needed. 
IMGPATH="$BASEPATH/images/$OS-server-cloudimg-amd64.img"

if [ -f $BASEPATH/images/$OS-server-cloudimg-amd64.img ]; then 
    echo "[+] Image present: $OS-server-cloudimg-amd64.img"
else
    echo "[!] Image does not exist. Downloading new cloudimg to: $BASEPATH/images/$OS-server-cloudimg-amd64.img"
    wget https://cloud-images.ubuntu.com/$OS/current/$OS-server-cloudimg-amd64.img -O $BASEPATH/images/$OS-server-cloudimg-amd64.img
fi 


# Create the VM disk and initialize the metadata image
if [ -f $BASEPATH/vms/$NAME/$NAME.qcow2 ]; then 
    echo "[!] VM Image already exists. Stopping here to prevent data loss!"
    exit 1 
fi 

mkdir -p $BASEPATH/vms/$NAME/
qemu-img convert -f qcow2 $BASEPATH/images/$OS-server-cloudimg-amd64.img $BASEPATH/vms/$NAME/$NAME.qcow2
qemu-img resize $BASEPATH/vms/$NAME/$NAME.qcow2 $DISK

# Create cloud-config file
echo "[+] Creating cloud-config file"
cat << EOF > $BASEPATH/vms/$NAME/cloud-config.yml
#cloud-config
hostname: $NAME
ssh_pwauth: False
password: $AUTH_PASSWD
chpasswd: { expire: False }
manage_etc_hosts: true
users: 
- default
- name:     $AUTH_USERNAME
  sudo:     ALL=(ALL) NOPASSWD:ALL
  groups:   sudo
  shell:    /bin/bash
  lock_passwd: true 
  ssh_authorized_keys: 
    - $AUTH_PUBKEY
EOF

# Create cloud-config device
cloud-localds $BASEPATH/vms/$NAME/metadata.img $BASEPATH/vms/$NAME/cloud-config.yml

# Spin up the VM
echo "[+] Starting VM import..."
virt-install --connect qemu:///system \
    --name $NAME \
    --memory $MEM \
    --vcpus $CPUS \
    --disk $BASEPATH/vms/$NAME/$NAME.qcow2,device=disk,bus=virtio \
    --disk $BASEPATH/vms/$NAME/metadata.img,device=cdrom \
    --os-type linux \
    --os-variant ubuntu20.04 \
    --virt-type kvm \
    --graphics none \
    --network network=default,model=virtio --import
