CIN="[\e[1;36mINFO\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

ok () {
  echo -e "$COK Done."
  sleep 2
}

# $1 returned variable name
read_user_input () {
  read -p "" _var
  export $1=$_var
}

# $1 input message
# $2 returned variable name
prompt_user_input () {
  echo -en "$CAC $1: "
  read_user_input $2
}

# $1 returned variable name
read_user_password () {
  read -sp "" _var
  echo ""
  export $1=$_var
}

# $1 input message
# $2 returned variable name
prompt_user_password () {
  while true
  do
    clear

    echo -en "$CAC $1: "
    read_user_password _pw1
    echo -en "$CAC Please enter your password again: "
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

# $1 input message
# $2 callback function
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

#
prompt_user_choice () {
  _items=$1
  select _item in "${_items[@]}"
  do
    if [[ -v $_items[$_item] ]]; then
      $2 $REPLY $_item
      # break;;
    fi
  done
}