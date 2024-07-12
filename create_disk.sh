#!/bin/bash
WHOAMI=$(whoami)
GROUP=diskusers

MOUNT_POINT=/mnt/disks/west4c-spyne-disk

lsblk
fdisk /dev/nvme0n2
mkfs.ext4 /dev/nvme0n2
blkid /dev/nvme0n2p1

mkdir -p ${MOUNT_POINT}

groupadd ${GROUP}
usermod -aG ${GROUP} ${WHOAMI}

chown -R :${GROUP} ${MOUNT_POINT}
chmod g+s ${MOUNT_POINT}
