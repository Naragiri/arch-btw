#!/bin/bash
source $PWD/scripts/lib.sh

#            _____   _____ _    _        ____ _________          __
#      /\   |  __ \ / ____| |  | |      |  _ \__   __\ \        / /
#     /  \  | |__) | |    | |__| |______| |_) | | |   \ \  /\  / / 
#    / /\ \ |  _  /| |    |  __  |______|  _ <  | |    \ \/  \/ /  
#   / ____ \| | \ \| |____| |  | |      | |_) | | |     \  /\  /   
#  /_/    \_\_|  \_\\_____|_|  |_|      |____/  |_|      \/  \/   
#

install_device=/dev/sda
luks_password=123
timezone=America/New_York
locale=en_US.UTF-8
keymap=en

username=nara
user_password=123
hostname=volta

if [ "$UID" -ne 0 ]; then
    echo -e "$CER This script needs to be run as root." >&2
    exit 3
fi

# lsblk
# prompt_user_input "Please select what device you want to install to (ex. sda,sdb,sdc)" install_device
# prompt_user_password "Please enter the password you want to use for LUKS encryption" luks_password
# prompt_user_input "Please enter a hostname for your system" hostname
# prompt_user_input "Please enter your /usr/share/zoneinfo (ex. America/New_York)" zoneinfo
# prompt_user_input "Please enter your locale name (ex. en_US.UTF-8)" locale
# prompt_user_input "Please enter your keymap name (ex. en)" keymap
# prompt_user_input "Please enter the name of your user account" username
# prompt_user_password "Please enter the password for your user account" user_password

_receive_proceed () {
  case $1 in
    n)
      exit 1
  esac
}

echo -e "$CWR Make sure you have edited the script configuration correctly.\n$CWR Failure to do so can cause irreverisble damage to your system."
prompt_user_yesno "Proceed?" _receive_proceed

echo -e "$CIN Formatting and partitioning $install_device." 
sgdisk -Z "$install_device"
sgdisk -n1:0:+512M -t1:ef00 -c1:BOOT -N2 -t2:8300 -c2:root $install_device
sleep 3
partprobe -s "$install_device"
sleep 3
echo -e "$COK Done."

echo -e "$CIN Setting up LUKS encryption"
echo -n "$luks_password" | cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/root -
echo -n "$luks_password" | cryptsetup luksOpen /dev/disk/by-partlabel/root crypted -

cryptsetup refresh --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent crypted

root_device="/dev/mapper/crypted"
echo -e "$COK Done."

echo -e "$CIN Formatting partitions"
mkfs.vfat -F 32 -n BOOT /dev/disk/by-partlabel/BOOT
mkfs.btrfs -f -L root $root_device
echo -e "$COK Done."