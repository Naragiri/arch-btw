#!/bin/bash

CIN="[\e[1;36mINFO\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

read_user_input () {
  read -p "" _var
  export $1=$_var
}

prompt_user_input () {
  echo -en "$CAC $1: "
  read_user_input $2
}


read_user_password () {
  read -sp "" _var
  echo ""
  export $1=$_var
}

prompt_user_password () {
  while true
  do
    echo -en "$CAC $1: "
    read_user_password _pw1
    echo -en "$CAC Please enter the password again: "
    read_user_password _pw2

    if [ $_pw1 == $_pw2 ]
    then
      export $2=$_pw1
      break
    else
      echo -e "$CER Passwords need to be the same."
      sleep 2
    fi
  done
}


prompt_user_yesno () {
  echo -e "$CAC $1 "
  select yn in "Yes" "No"; do
    case $yn in
      [Yes]*) 
        $2 y 
        break;;
      [No]*) 
        $2 n 
        break;;
    esac
  done
}