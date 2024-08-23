#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh
source $CONFIG_FILE

packages=(
  base
  linux-zen
  linux-zen-headers
  linux-firmware
  "$MICROCODE"-ucode
  # vim 
  # openssh 
  # reflector 
  # rsync 
  # terminus-font
  # opendoas 
  # git
  # neofetch
  # e2fsprogs
  # dosfstools
  # btrfs-progs
  # plymouth
  # os-prober
  # grub
  # networkmanager
  # xdg-user-dirs
  # pipewire
  # wireplumber
  # pipewire-pulse
  # pipewire-alsa
  # pipewire-jack
)

pacstrap -K /mnt "${packages[@]}"