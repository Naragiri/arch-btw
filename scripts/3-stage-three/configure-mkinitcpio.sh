#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh

echo "quiet rw" > /mnt/etc/kernel/cmdline

sed -i \
    -e 's/base udev/base systemd plymouth/g' \
    -e 's/keymap consolefont/sd-vconsole btrfs/g' \
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

arch-chroot /mnt mkinitcpio -p linux-zen