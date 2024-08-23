#!/bin/bash
export ARCH_BTW_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
export ARCH_BTW_SCRIPTS=$ARCH_BTW_DIR/scripts
source $ARCH_BTW_DIR/lib/lib.sh

#  -------------------------------------------------------
#      _             _           ____ _______        __  
#     / \   _ __ ___| |__       | __ )_   _\ \      / /  
#    / _ \ | '__/ __| '_ \ _____|  _ \ | |  \ \ /\ / /   
#   / ___ \| | | (__| | | |_____| |_) || |   \ V  V /    
#  /_/   \_\_|  \___|_| |_|     |____/ |_|    \_/\_/     
# -------------------------------------------------------
#        An Arch Linux install script by Naragiri.            
# ------------------------------------------------------- 


check_root
clear

install_device=/dev/sda
luks_password="test"
mirocode_cpu=intel
timezone=America/New_York
locale=en_US.UTF-8
keymap=en
hostname=volta
username=nara
shell=zsh



# ---- PARTITIONING ----
# ----------------------

echo -e "$CIN Formatting and partitioning $install_device." 
sgdisk -Z "$install_device"
sgdisk -n1:0:+512M -t1:ef00 -c1:BOOT -N2 -t2:8300 -c2:root $install_device
sleep 3
partprobe -s "$install_device"
sleep 3
echo -e "$COK Done."

# ---- LUKS ENCRYPTION ----
# -------------------------

echo -e "$CIN Setting up LUKS encryption"

echo -n "${luks_password}" | cryptsetup -y -v luksFormat /dev/disk/by-partlabel/root -
echo -n "${luks_password}" | cryptsetup open /dev/disk/by-partlabel/root crypted -
# echo -n "${luks_password}" | cryptsetup refresh --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent crypted -
crypted_uuid=$(blkid -s UUID -o value /dev/disk/by-partlabel/root)
root_device="/dev/mapper/crypted"
# root_device=/dev/disk/by-partlabel/root
echo -e "$COK Done."

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
# btrfs subvolume create /mnt/@
# btrfs subvolume create /mnt/@home
# btrfs subvolume create /mnt/@var
# btrfs subvolume create /mnt/@tmp
# btrfs subvolume create /mnt/@.snapshots
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
sed -i "/^#ParallelDownloads/s/^#//" /etc/pacman.conf
sed -i "/^#Color/s/^#//" /etc/pacman.conf
pacman -Syy

bootstrap_packages=(
    base
    linux-zen
    linux-zen-headers
    linux-firmware
    btrfs-progs
    "$mirocode_cpu"-ucode
)

pacstrap -K /mnt "${bootstrap_packages[@]}"
genfstab -U /mnt >> /mnt/etc/fstab

system_packages=(
    zsh
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

sed -i "/^#ParallelDownloads/s/^#//" /mnt/etc/pacman.conf
sed -i "/^#Color/s/^#//" /mnt/etc/pacman.conf
# reflector --save /mnt/etc/pacman.d/mirrorlist --protocol https --country us --latest 5 --sort rate
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
arch-chroot /mnt pacman -Syy

arch-chroot /mnt pacman -S --noconfirm --needed "${system_packages[@]}" -y

sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
systemd-firstboot --root /mnt --keymap="$keymap" --locale="$locale" --locale-messages="$locale" --hostname="$hostname" --timezone="$timezone" --setup-machine-id --welcome=false
arch-chroot /mnt locale-gen

echo "quiet rw" > /mnt/etc/kernel/cmdline

sed -i \
    -e 's/base udev/base systemd plymouth/g' \
    -e 's/keymap consolefont/sd-vconsole btrfs sd-encrypt/g' \
    's/BINARIES=()/BINARIES=(btrfs setfont)/g' \
    /mnt/etc/mkinitcpio.conf

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

arch-chroot /mnt mkinitcpio -P

sed -i \
    -e 's/loglevel=.*"/loglevel=3 quiet splash"/g' \
    -e '/^#GRUB_DISABLE_OS_PROBER/s/^#//' \
    -e '/^#GRUB_ENABLE_CRYPTODISK/s/^#//' \
    -e "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${crypted_uuid}:crypted root=$root_device %g" \
    /mnt/etc/default/grub

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# sed -i -e "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub

# /bin/bash $ARCH_BTW_SCRIPTS/setup-grub-btrfs-timeshift.sh

echo "permit persist :wheel" >> /mnt/etc/doas.conf
# /bin/bash $ARCH_BTW_SCRIPTS/setup-zsh.sh

arch-chroot /mnt useradd -mG wheel,video,audio -s /bin/$shell $username

mkdir /mnt/home/$username/arch-btw-tools

mv ./tools/* /mnt/home/$username/arch-btw-tools
mv ./lib/* /mnt/home/$username/arch-btw-tools/
arch-chroot /mnt chown -R $username:$username /home/$username/arch-btw-tools

echo "export ARCH_BTW_DIR=/home/$username/arch-btw-tools/" >> /mnt/home/$username/.profile
arch-chroot /mnt chown $username:$username /mnt/home/$username/.profile

mv ./wallpapers/ /mnt/home/$username/.wallpapers/
arch-chroot /mnt chown -R $username:$username /mnt/home/$username/.wallpapers

echo -e "$CAC Enter user password."
arch-chroot /mnt passwd $username
arch-chroot /mnt usermod -L root

# if [ $zsh == 'zsh' ]; then
#   echo "$COK Setting up zsh"
# fi