#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh

reflector --save /mnt/etc/pacman.d/mirrorlist --protocol https --country us --latest 5 --sort rate
sed -i \
  -e "/^#ParallelDownloads/s/^#//" \
  -e "/^#Color/s/^#//" \
  /mnt/etc/pacman.conf
arch-chroot /mnt pacman -Syy