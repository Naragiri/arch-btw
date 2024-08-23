#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh

packages=(
  vim 
  openssh 
  reflector 
  rsync 
  terminus-font
  opendoas 
  git
  neofetch
  e2fsprogs
  dosfstools
  btrfs-progs
  plymouth
  os-prober
  grub
  networkmanager
  xdg-user-dirs
  pipewire
  wireplumber
  pipewire-pulse
  pipewire-alsa
  pipewire-jack
)

arch-chroot /mnt pacman -S --noconfirm --needed "${packages[@]}" -y