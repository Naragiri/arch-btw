#!/bin/bash
# source $PWD/lib.sh

CIN="[\e[1;36mINFO\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

#            _____   _____ _    _        ____ _________          __
#      /\   |  __ \ / ____| |  | |      |  _ \__   __\ \        / /
#     /  \  | |__) | |    | |__| |______| |_) | | |   \ \  /\  / / 
#    / /\ \ |  _  /| |    |  __  |______|  _ <  | |    \ \/  \/ /  
#   / ____ \| | \ \| |____| |  | |      | |_) | | |     \  /\  /   
#  /_/    \_\_|  \_\\_____|_|  |_|      |____/  |_|      \/  \/   
#

install_device=/dev/sda
timezone=America/New_York
locale=en_US.UTF-8
keymap=en
hostname=volta
username=nara

if [ "$UID" -ne 0 ]; then
    echo -e "$CER This script needs to be run as root." >&2
    exit 3
fi

# _receive_proceed () {
#   case $1 in
#     n)
#       exit 1
#   esac
# }

# echo -e "$CWR Make sure you have edited the script configuration correctly.\n$CWR Failure to do so can cause irreverisble damage to your system."
# prompt_user_yesno "Proceed?" _receive_proceed

echo -e "$CIN Formatting and partitioning $install_device." 
sgdisk -Z "$install_device"
sgdisk -n1:0:+512M -t1:ef00 -c1:BOOT -N2 -t2:8300 -c2:root $install_device
sleep 3
partprobe -s "$install_device"
sleep 3
echo -e "$COK Done."

echo -e "$CIN Setting up LUKS encryption"
# cryptsetup luksFormat --type luks1 /dev/disk/by-partlabel/root -
# cryptsetup luksOpen /dev/disk/by-partlabel/root crypted -

# cryptsetup refresh --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent crypted

# root_device="/dev/mapper/crypted"
root_device=/dev/disk/by-partlabel/root
echo -e "$COK Done."

echo -e "$CIN Formatting partitions"
mkfs.vfat -F 32 -n BOOT /dev/disk/by-partlabel/BOOT
mkfs.btrfs -f -L root "$root_device"
echo -e "$COK Done."

mount -o "compress=zstd:1" "$root_device" /mnt
mkdir -p /mnt/boot/efi
mount /dev/disk/by-partlabel/BOOT /mnt/boot/efi

for _vol in var var/log var/cache var/tmp srv home; do
    btrfs subvolume create "/mnt/$_vol"
done

chattr +C /mnt/home

reflector --save /etc/pacman.d/mirrorlist --protocol https --country us --latest 5 --sort rate

bootstrap_packages=(
  base
  linux
  linux-firmware
  intel-ucode
  vim 
  openssh 
  reflector 
  rsync 
  terminus-font
  opendoas 
  git
  neofetch
  cryptsetup
  e2fsprogs
  dosfstools
  grub
  grub-btrfs
  networkmanager
)

sed -i -e "/^#ParallelDownloads/s/^#//" /etc/pacman.conf
sed -i -e "/^#Color/s/^#//" /etc/pacman.conf
pacstrap -K /mnt "${bootstrap_packages[@]}"

sed -i  -e "/^#$locale/s/^#//" /mnt/etc/locale.gen
systemd-firstboot --root /mnt --keymap="$keymap" --locale="$locale" --locale-messages="$locale" --hostname="$hostname" --timezone="$timezone" --setup-machine-id --welcome=false
arch-chroot /mnt locale-gen

sed -i -e "/^#ParallelDownloads/s/^#//" /mnt/etc/pacman.conf
sed -i -e "/^#Color/s/^#//" /mnt/etc/pacman.conf
reflector --save /mnt/etc/pacman.d/mirrorlist --protocol https --country us --latest 5 --sort rate

# echo "quiet rw" > /mnt/etc/kernel/cmdline

# sed -i -e 's/base udev/base systemd/g' -e 's/keymap consolefont/sd-vconsole btrfs sd-encrypt/g' /mnt/etc/mkinitcpio.conf
sed -i -e 's/keymap consolefont/keymap consolefont btrfs/g' /mnt/etc/mkinitcpio.conf
# sed -i -e 's/BINARIES=()/BINARIES=(btrfs setfont)/g' /mnt/etc/mkinitcpio.conf

# sed -i \
#     -e '/^#ALL_config/s/^#//' \
#     -e '/^#default_uki/s/^#//' \
#     -e '/^#default_options/s/^#//' \
#     -e 's/default_image=/#default_image=/g' \
#     -e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/g" \
#     /mnt/etc/mkinitcpio.d/linux.preset


# declare $(grep default_uki /mnt/etc/mkinitcpio.d/linux.preset)
# arch-chroot /mnt mkdir -p "$(dirname "${default_uki//\"}")"

systemctl --root /mnt enable NetworkManager
# systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager
# systemctl --root /mnt mask systemd-networkd

arch-chroot /mnt mkinitcpio -p linux

# sed -i -e '/^#GRUB_ENABLE_CRYPTODISK/s/^#//' /mnt/etc/default/grub
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable

# echo "menuentry "Arch Linux" {
# 	insmod fat
# 	insmod chain
# 	search --no-floppy --set=root --fs-uuid $(blkid -s PARTUUID -o value $install_device)
# 	chainloader /EFI/Linux/arch-linux.efi
# }" >> /mnt/etc/grub.d/40_arch

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

arch-chroot /mnt passwd root

echo "permit :wheel" >> /mnt/etc/doas.conf