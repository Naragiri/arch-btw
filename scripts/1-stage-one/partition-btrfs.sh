#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh
source $CONFIG_FILE

sgdisk -Z "$INSTALL_DEVICE"
sgdisk -n1:0:+512M -t1:ef00 -c1:BOOT -N2 -t2:8300 -c2:root $INSTALL_DEVICE
sleep 3
partprobe -s "$INSTALL_DEVICE"
sleep 3

set_option "BOOT_DEVICE" "/dev/disk/by-partlabel/BOOT"
set_option "ROOT_DEVICE" "/dev/disk/by-partlabel/root"