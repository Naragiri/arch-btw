#!/bin/bash
source /arch-btw/scripts/lib.sh
LUKS=$1

# edit these.
username=nara
hostname=volta
locale=en_US.UTF-8
zoneinfo=America/New_York
kb_layout=us

echo -e "$CIN Now preforming post installation setup."
sleep 6

clear

echo -e "$CIN Synchronizing system time and mapping localtime"
ln -sf /usr/share/zoneinfo/$zoneinfo /etc/localtime
hwclock --systohc
echo -e "$COK Done."

echo -e "$CIN Generating system configurations"
sed -i -e "/^#"$locale"/s/^#//" /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "FONT=ter-128n" >> /etc/vconsole.conf
echo "KEYMAP=$kb_layout" >> /etc/vconsole.conf
echo -e "$COK Done."

echo -e "$CIN Configuring host file."
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo -e "$COK Done."

echo -e "$CIN Updating & synchronizing Arch Linux mirrors in installed system."
reflector --latest 5 --sort rate --country us --save /etc/pacman.d/mirrorlist
pacman -Syy
echo -e "$COK Done."

echo -e "$CIN Installing base paclist files."
#TODO: .paclist file loader.
sed -i -e "/^#ParallelDownloads/s/^#//" /etc/pacman.conf
sed -i -e "/^#Color/s/^#//" /etc/pacman.conf
pacman --noconfirm -S grub networkmanager efibootmgr plymouth xdg-user-dirs network-manager-applet wpa_supplicant bluez bluez-utils cups alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack flatpak os-prober ntfs-3g exa bat btop zip unzip neofetch grub-btrfs pacman-contrib zsh intel-ucode
echo -e "$COK Done."

echo -e "$CIN Configuring and updating mkinitcpio."
sed -i 's/BINARIES=()/BINARIES=(btrfs setfont)/g' /etc/mkinitcpio.conf

if [[ $LUKS == 1 ]]; then
    sed -i -e 's/keymap consolefont/keymap consolefont btrfs encrypt/g' /etc/mkinitcpio.conf
  else
    sed -i -e 's/keymap consolefont/keymap consolefont btrfs/g' /etc/mkinitcpio.conf
fi

# sed -i -e 's/base udev/base systemd/g' -e 's/keymap consolefont/sd-vconsole btrfs sd-encrypt/g' /etc/mkinitcpio.conf
# sed -i -e '/^#ALL_config/s/^#//' -e '/^#default_uki/s/^#//' -e '/^#default_options/s/^#//' -e 's/default_image=/#default_image=/g' -e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/g" /etc/mkinitcpio.d/linux.preset

# declare $(grep default_uki /etc/mkinitcpio.d/linux.preset)
# mkdir -p "$(dirname "${default_uki//\"}")"

mkinitcpio -p linux
echo -e "$COK Done."

echo -e "$CIN Enabling installed services."
systemctl enable NetworkManager bluetooth sshd reflector.timer fstrim.timer
echo -e "$COK Done."

echo -e "$CIN Installing systemd bootloader."
bootctl install --esp-path=/boot/efi
echo -e "$COK Done."

# echo -e "$CIN Installing grub & generating initial config."
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable
# grub-mkconfig -o /boot/grub/grub.cfg
# echo -e "$COK Done."

# clear

echo -e "$CIN Now setting up root & user configuration."
echo -e "$CAC Please enter a password for the root user."
passwd root

echo -e "$CIN Creating user."
useradd -mG wheel -s /bin/zsh $username

echo -e "$CAC Please enter a password for ${username}."
passwd $username

echo -e "$COK Done."

echo -e "$CAC Doing final cleanup work."
echo "permit :wheel" >> /etc/doas.conf

mkdir /home/$username/arch-scripts
mv /arch-btw/scripts/* /home/$username/arch-scripts/
rm -rf /arch-btw

sync
clear

echo -e "$CIN Done. Reboot to enjoy your new fully installed Arch Linux system."