#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh

#            _____   _____ _    _        ____ _________          __
#      /\   |  __ \ / ____| |  | |      |  _ \__   __\ \        / /
#     /  \  | |__) | |    | |__| |______| |_) | | |   \ \  /\  / / 
#    / /\ \ |  _  /| |    |  __  |______|  _ <  | |    \ \/  \/ /  
#   / ____ \| | \ \| |____| |  | |      | |_) | | |     \  /\  /   
#  /_/    \_\_|  \_\\_____|_|  |_|      |____/  |_|      \/  \/   
#

packages=(
  timeshift 
  inotify-tools
  grub-btrfs
)

arch-chroot /mnt pacman -S --needed --noconfirm -y "${packages[@]}"

systemctl --root /mnt enable grub-btrfsd
sed -i -e 's/ExecStart=.*/ExecStart=\/usr\/bin\/grub-btrfsd --syslog --timeshift-auto/' /mnt/usr/lib/systemd/system/grub-btrfsd.service
# $sudo_cmd systemctl daemon-reload
# $sudo_cmd systemctl restart grub-btrfsd
echo -e "$COK Done."