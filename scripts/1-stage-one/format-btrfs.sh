#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh
source $CONFIG_FILE

mkfs.vfat -F 32 -n BOOT "$BOOT_DEVICE"
mkfs.btrfs -f -L root "$ROOT_DEVICE"

mount $ROOT_DEVICE /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@log
umount /mnt

mount -o compress=zstd:1,noatime,subvol=@ $ROOT_DEVICE /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
mount -o compress=zstd:1,noatime,subvol=@home $ROOT_DEVICE /mnt/home
mount -o compress=zstd:1,noatime,subvol=@snapshots $ROOT_DEVICE /mnt/.snapshots
mount -o compress=zstd:1,noatime,subvol=@cache $ROOT_DEVICE /mnt/var/cache
mount -o compress=zstd:1,noatime,subvol=@log $ROOT_DEVICE /mnt/var/log
mount /dev/disk/by-partlabel/BOOT /mnt/boot/efi

chattr +C /mnt/home