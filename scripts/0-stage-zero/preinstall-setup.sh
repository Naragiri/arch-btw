#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh

timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring -y
pacman -S --noconfirm --needed pacman-contrib terminus-font -y
setfont ter-v22b