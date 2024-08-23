source $HOME/arch-btw-tools/lib/lib.sh

check_root

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector --latest 5 --sort rate --country us --save /etc/pacman.d/mirrorlist