#!/bin/bash
source $ARCH_BTW_DIR/lib/lib.sh

check_root

# sudo_cmd=doas
terminal=alacritty
# TODO: FIX
# resolution=2440x1440

packages=(
  xorg-server
  xorg-xrandr
  xorg-xsetroot
  sddm
  bspwm
  sxhkd
  polkit-gnome
  $terminal
  feh
  arandr
  rofi
  polybar
  dunst
)


for pkg in ${packages[@]}; do
    install_software $pkg 
done

# $sudo_cmd pacman -S --needed --noconfirm -y "${packages[@]}"
# $sudo_cmd systemctl enable sddm

mkdir -p $HOME/.config/{bspwm,sxhkd}

BSPWM_CFG=$HOME/.config/bspwm
AUTOSTART=$BSPWM_CFG/autostart.sh

cp /usr/share/doc/bspwm/examples/bspwmrc $HOME/.config/bspwm/
sed -i 's/pgrep.*/xsetroot -cursor_name left_ptr\nsetxkbmap us\n$HOME\/.config\/bspwm\/autostart.sh/g' $BSPWM_CFG/bspwmrc
echo 'pgrep -x sxhkd > /dev/null || sxhkd &' >> $AUTOSTART
echo 'pgrep -x polkit-gnome > /dev/null || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &' >> $AUTOSTART
echo 'pgrep -x polybar > /dev/null || polybar &' >> $AUTOSTART

mkdir -p $HOME/.rice_config
echo "$HOME/Pictures/wallpapers/neon-tokyo-anime.jpg" >> $HOME/.rice_config/wallpaper

echo "feh --bg-scale $(cat "$HOME/.rice_config/wallpaper")" >> $BSPWM_CFG/set_wallpaper.sh
echo "$BSPWM_CFG/set_wallpaper.sh" >> $AUTOSTART

chmod +x $BSPWM_CFG/set_wallpaper.sh
chmod +x $AUTOSTART

cp /usr/share/doc/bspwm/examples/sxhkdrc $HOME/.config/sxhkd/
sed -i -e "s/urxvt/$terminal/g" -e 's/dmenu_run/rofi -show drun/g' $HOME/.config/sxhkd/sxhkdrc

# chown -R $USERNAME:$USERNAME .rice_config
echo Done.




