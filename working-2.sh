#!/bin/bash
export ARCH_BTW_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source $ARCH_BTW_DIR/lib/lib.sh

#            _____   _____ _    _        ____ _________          __
#      /\   |  __ \ / ____| |  | |      |  _ \__   __\ \        / /
#     /  \  | |__) | |    | |__| |______| |_) | | |   \ \  /\  / / 
#    / /\ \ |  _  /| |    |  __  |______|  _ <  | |    \ \/  \/ /  
#   / ____ \| | \ \| |____| |  | |      | |_) | | |     \  /\  /   
#  /_/    \_\_|  \_\\_____|_|  |_|      |____/  |_|      \/  \/   
#

install_device=/dev/sda
mirocode_cpu=intel
timezone=America/New_York
locale=en_US.UTF-8
keymap=en
hostname=volta
username=nara

shell=zsh

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

# echo -e "$CIN Setting up LUKS encryption"
# cryptsetup luksFormat --type luks1 /dev/disk/by-partlabel/root -
# cryptsetup luksOpen /dev/disk/by-partlabel/root crypted -

# cryptsetup refresh --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent crypted

# root_device="/dev/mapper/crypted"
root_device=/dev/disk/by-partlabel/root
# echo -e "$COK Done."

echo -e "$CIN Formatting partitions"
mkfs.vfat -F 32 -n BOOT /dev/disk/by-partlabel/BOOT
mkfs.btrfs -f -L root "$root_device"
echo -e "$COK Done."

mount $root_device /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@log
umount /mnt

mount -o compress=zstd:1,noatime,subvol=@ $root_device /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
mount -o compress=zstd:1,noatime,subvol=@home $root_device /mnt/home
mount -o compress=zstd:1,noatime,subvol=@snapshots $root_device /mnt/.snapshots
mount -o compress=zstd:1,noatime,subvol=@cache $root_device /mnt/var/cache
mount -o compress=zstd:1,noatime,subvol=@log $root_device /mnt/var/log
mount /dev/disk/by-partlabel/BOOT /mnt/boot/efi

chattr +C /mnt/home

reflector --save /etc/pacman.d/mirrorlist --protocol https --country us --latest 5 --sort rate
pacman -Syy

bootstrap_packages=(
  base
  linux-zen
  linux-zen-headers
  linux-firmware
  "$mirocode_cpu"-ucode
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

sed -i "/^#ParallelDownloads/s/^#//" /etc/pacman.conf
sed -i "/^#Color/s/^#//" /etc/pacman.conf
pacstrap -K /mnt "${bootstrap_packages[@]}"

genfstab -U /mnt >> /mnt/etc/fstab

sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
systemd-firstboot --root /mnt --keymap="$keymap" --locale="$locale" --locale-messages="$locale" --hostname="$hostname" --timezone="$timezone" --setup-machine-id --welcome=false
arch-chroot /mnt locale-gen

sed -i "/^#ParallelDownloads/s/^#//" /mnt/etc/pacman.conf
sed -i "/^#Color/s/^#//" /mnt/etc/pacman.conf
reflector --save /mnt/etc/pacman.d/mirrorlist --protocol https --country us --latest 5 --sort rate
arch-chroot /mnt pacman -Syy

echo "quiet rw" > /mnt/etc/kernel/cmdline

sed -i -e 's/base udev/base systemd plymouth/g' -e 's/keymap consolefont/sd-vconsole btrfs/g' /mnt/etc/mkinitcpio.conf
sed -i 's/BINARIES=()/BINARIES=(btrfs setfont)/g' /mnt/etc/mkinitcpio.conf

sed -i \
    -e '/^#ALL_config/s/^#//' \
    -e '/^#default_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    -e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/g" \
    /mnt/etc/mkinitcpio.d/linux.preset


declare $(grep default_uki /mnt/etc/mkinitcpio.d/linux.preset)
arch-chroot /mnt mkdir -p "$(dirname "${default_uki//\"}")"

systemctl --root /mnt enable systemd-resolved systemd-homed systemd-timesyncd sshd reflector.timer fstrim.timer NetworkManager
systemctl --root /mnt mask systemd-networkd

arch-chroot /mnt mkinitcpio -p linux-zen

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
sed -i -e 's/loglevel=.*"/loglevel=3 quiet splash"/g' -e '/^#GRUB_DISABLE_OS_PROBER/s/^#//' /mnt/etc/default/grub
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo "permit persist :wheel" >> /mnt/etc/doas.conf
arch-chroot /mnt useradd -mG wheel,video,audio -s /bin/bash $username

mkdir /mnt/home/$username/arch-btw-tools

mv ./tools/* /mnt/home/$username/arch-btw-tools
arch-chroot /mnt chown -R $username:$username /home/$username/arch-btw-tools

echo 'export ARCH_BTW_TOOLS=$HOME/arch-btw-tools/' >> /mnt/home/$username/.profile

mkdir -p /mnt/home/$username/Pictures/
mv ./wallpapers/ /mnt/home/$username/Pictures/wallpapers/
arch-chroot /mnt chown -R $username:$username /home/$username/Pictures/wallpapers

arch-chroot /mnt passwd $username
arch-chroot /mnt usermod -L root

if [ $zsh == 'zsh' ]; then

fi