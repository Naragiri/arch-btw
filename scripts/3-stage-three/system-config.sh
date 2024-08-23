#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh
source $CONFIG_FILE

sed -i "/^#$LOCALE/s/^#//" /mnt/etc/locale.gen
systemd-firstboot --root /mnt --keymap="$KEYMAP" --locale="$LOCALE" --locale-messages="$LOCALE" --hostname="$HOSTNAME" --timezone="$TIMEZONE" --setup-machine-id --welcome=false
arch-chroot /mnt locale-gen