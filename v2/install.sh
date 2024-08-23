#!/bin/bash
source $PWD/scripts/lib.sh

if [[ "$UID" -ne 0 ]]; then
    echo -e "$CWR This script needs to be run as root!" >&2
    exit 3
fi

# clear
# lsblk -d | tail -n+2 | awk {'print $1" "$4'}
# prompt_user_input "Please select a drive to install Arch Linux to (ex. sda)" install_drive
# ok

handle_gaming_result () {
  case $1 in
    y)
      echo "exdee";;
    n)
      exit 1;;
  esac
}

clear
prompt_user_yesno "Do you like gaming?" handle_gaming_result
ok

# clear
# prompt_user_password "gib me ur passwd" user_pass
# ok

handle_item_prompt () {
  index=$1
  item=$2

  echo $index $item
}

clear
choices=("Test1" "test2" "tEst3")
prompt_user_choice $choices handle_item_prompt
ok