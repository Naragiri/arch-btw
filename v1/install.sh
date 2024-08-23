#!/bin/bash
source ./scripts/lib.sh
LUKS=0

clear

echo -e "$CWR The script will attempt to setup an Arch Linux install using BTRFS with LUKS encryption optionally for UEFI systems."
echo -e "$CWR Please make sure you edit the configuration at the beginning of post-install.sh before continuing."

sleep 1

lsblk
echo -en "$CAC Enter the name of the drive you want to install Arch Linux on. (eg. sda) "
read -p "" drive

echo -e "$CWR This script will now attempt to zap and partition the drive."
echo -e "$CWR Please back-up any important data before continuing with the installation."
echo -e "$CWR I'm not responsible for any data loss as a result of this."
echo -en "$CAC Proceed? (Yy,Nn) "

while true; do
  read -p "" yn
  case $yn in
    [Yy]*) 
      break;;
    [Nn]*) 
      exit 1;;
    *) 
      echo -e "$CER You must enter one of the following: (Yy,Nn) "
      sleep 1
  esac
done

clear

echo -e "$CIN Zapping and partitioning drive $drive."
sgdisk -n1:0:+512M -t1:ef00 -c1:BOOT -n2:513M:+4G -t2:8200 -c2:swap -N3 -t2:8300 -c3:root /dev/$drive
sleep 2
partprobe -s /dev/$drive
sleep 2
echo -e "$COK Done."

echo -en "$CAC Would you like to install with LUKS encryption? (Yy,Nn) "
while true; do
  read -p "" yn
  case $yn in
    [Yy]*) 
      echo -e "$CIN Setting up LUKS encryption on root drive."
      cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/root
      echo -e "$CAC Enter your encryption password again."
      cryptsetup luksOpen /dev/disk/by-partlabel/root crypted
      echo -e "$COK Done."
      LUKS=1
      root=/dev/mapper/crypted
      break;;
    [Nn]*) 
      root=/dev/disk/by-partlabel/root
      break;;
    *) 
      echo -e "$CER You must enter one of the following: (Yy/Nn) "
      sleep 1
  esac
done

echo -e "$CIN Now beginning installation of Arch Linux."
echo -e "$CIN You will be prompted for input at the end."
echo -e "$CIN This will take a few minutes."

sleep 6
clear

echo -e "$CIN Synchronizing NTP time."
timedatectl set-ntp true
echo -e "$COK Done."

echo -e "$CIN Formatting boot partition to FAT32."
mkfs.vfat -F 32 -n BOOT /dev/disk/by-partlabel/BOOT
echo -e "$COK Done."

echo -e "$CIN Formatting swap partition."
mkswap -L swap /dev/disk/by-partlabel/swap
echo -e "$COK Done."

echo -e "$CIN Formatting root partition with BTRFS"
mkfs.btrfs -f -L root $root
echo -e "$COK Done."

echo -e "$CIN Mounting partitions and creating BTRFS subvolumes"
swapon /dev/disk/by-partlabel/swap

mount $root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@log
umount /mnt

mount -o compress=zstd:1,noatime,subvol=@ $root /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
mount -o compress=zstd:1,noatime,subvol=@cache $root /mnt/var/cache
mount -o compress=zstd:1,noatime,subvol=@home $root /mnt/home
mount -o compress=zstd:1,noatime,subvol=@log $root /mnt/var/log
mount -o compress=zstd:1,noatime,subvol=@snapshots $root /mnt/.snapshots

mount /dev/disk/by-partlabel/BOOT /mnt/boot/efi
echo -e "$COK Done."

echo -e "$CIN Updating & synchronizing Arch Linux mirrors"
reflector --latest 5 --sort rate --country us --save /etc/pacman.d/mirrorlist
pacman -Syy
echo -e "$COK Done."

echo -e "$CIN Installing base packages."
sed -i -e "/^#ParallelDownloads/s/^#//" /etc/pacman.conf
sed -i -e "/^#Color/s/^#//" /etc/pacman.conf
pacstrap -K /mnt base opendoas git linux linux-firmware vim openssh reflector rsync terminus-font
echo -e "$COK Done."

echo -e "$CIN Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "$COK Done."

mkdir /mnt/arch-btw
cp -r ../arch-btw/* /mnt/arch-btw/

echo -e "$CIN Running post install script in chroot."
arch-chroot /mnt ./arch-btw/post-install.sh $LUKS

