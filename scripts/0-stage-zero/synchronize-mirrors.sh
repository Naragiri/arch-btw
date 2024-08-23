#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh

reflector --save /etc/pacman.d/mirrorlist --protocol https --country us --latest 5 --sort rate
sed -i \
  -e "/^#ParallelDownloads/s/^#//" \
  -e "/^#Color/s/^#//" \
  /etc/pacman.conf
pacman -Syy