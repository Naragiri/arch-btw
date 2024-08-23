#!/bin/bash

#            _____   _____ _    _        ____ _________          __
#      /\   |  __ \ / ____| |  | |      |  _ \__   __\ \        / /
#     /  \  | |__) | |    | |__| |______| |_) | | |   \ \  /\  / / 
#    / /\ \ |  _  /| |    |  __  |______|  _ <  | |    \ \/  \/ /  
#   / ____ \| | \ \| |____| |  | |      | |_) | | |     \  /\  /   
#  /_/    \_\_|  \_\\_____|_|  |_|      |____/  |_|      \/  \/   
#

# Install script by Naragiri
# This script partitions and installs a base Arch Linux system for UEFI systems.
# The installation with come with the GRUB bootloader, LUKS2 encryiptions
# and the UKI system image with systemd.

##############################
#######   EDIT THESE   #######
##############################

# By changing the value of SAFETY_CHECK you understand this process will zap
# and partiton the disk you specify below. You understand the risk of data loss
# from carelessness and that i'm not responsible for any data loss as a result.
# Change value to 1 if you acknowledge the above.
SAFETY_CHECK=1

# Use lsblk to figure this out.
# Do not inclue the /dev/ portion.
install_disk=sda
luks_password=123
timezone=America/New_York
locale=en_US.UTF-8
keymap=en

username=nara
user_password=123
hostname=volta

#####################################
#######   DO NOT EDIT BELOW   #######
#####################################

CIN="[\e[1;36mINFO\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

if [ "$UID" -ne 0 ]; then
    echo -e "$CER This script needs to be run as root." >&2
    exit 3
fi

if [ "$SAFETY_CHECK" -ne 1 ]; then
    echo -e "$CER Please read over and edit the script before running this." >&2
    exit 3
fi

echo -e "$CIN Welcome to the Arch Linux installer script by Naragiri."