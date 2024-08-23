CIN="[\e[1;36mINFO\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

show_logo () {
echo -ne "
-----------------------------------------------------------
       _             _           ____ _______        __  
      / \   _ __ ___| |__       | __ )_   _\ \      / /  
     / _ \ | '__/ __| '_ \ _____|  _ \ | |  \ \ /\ / /   
    / ___ \| | | (__| | | |_____| |_) || |   \ V  V /    
   /_/   \_\_|  \___|_| |_|     |____/ |_|    \_/\_/     
-----------------------------------------------------------
         An Arch Linux install script by Naragiri.            
-----------------------------------------------------------  
"
}

check_root() {
    if [ "$UID" -ne 0 ]; then
        echo -e "$CER This script needs to be run as root." >&2
        exit 3
    fi
}

CONFIG_FILE=/tmp/arch-btw.cfg
if [ ! -f $CONFIG_FILE ]; then
    touch -f $CONFIG_FILE
fi

set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then
        sed -i -e "/^${1}.*/d" $CONFIG_FILE
    fi
    echo "${1}=${2}" >>$CONFIG_FILE
}

show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -n "."
        sleep 2
    done
    echo -en "$COK Done!\n"
    sleep 2
}

install_software() {
    if pacman -Q $1 &>> /dev/null ; then
        echo -e "$COK $1 is already installed."
    else
        echo -en "$CNT - Now installing $1 ."
        pacman -S --noconfirm -y $1 &>> /dev/null
        show_progress $!

        if pacman -Q $1 &>> /dev/null ; then
            echo -e "$COK $1 was installed successfully."
        else
            echo -e "$CER $1 couldn't be installed successfully."
            exit
        fi
    fi
}