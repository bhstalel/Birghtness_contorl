#!/bin/bash

# Base directory for the Linux's sysfs backlight class
#BL_BASE_DIR="${BL_BASE_DIR:-/sys/class/backlight}"

BL_DENTRY="/sys/class/backlight/intel_backlight"
BL_MAX_BR="${BL_DENTRY}/max_brightness"
BL_CURR_BR="${BL_DENTRY}/brightness"

# Read brightness context one time
BL_MAX_BR_VAL=$(cat ${BL_MAX_BR})
BL_CURR_BR_VAL=$(cat ${BL_CURR_BR})
BL_MIN_BR_VAL="100"

# Calculate the value that be used for increase/decrease
BL_10PERC=$((${BL_MAX_BR_VAL} / 10))

usage(){ 
  printf '%s\n' \
    " A tool that helps you controll the brightness of your screen backlight.
      Usage: <option> <value>
      Available options:
      -I | -i           : increase the level by 10%
      -D | -d           : decreases the level by 10%   
      -U | -u <val>     : increases the level by <val>
      -L | -l <val>     : increases the level by <val>
      -R | -r           : returns the birghtness level
      -h | --help       : help"
}

do_read_brightness(){

  local BR_VAL_PERC=$(( ($BL_CURR_BR_VAL * 100) / $BL_MAX_BR_VAL))
  echo "${BR_VAL_PERC}%"
}
do_update_brightness_by_val(){
 local tmpV=$BL_10PERC
 local op=${1}
 local val=${2}
#  echo $val
 BL_10PERC=$(( ($val * $BL_MAX_BR_VAL) / 100 ))
 do_update_brightness ${1}
 BL_10PERC=$tmpV

}
do_update_brightness(){
  # This should be true or false
  local operation=${1}
  local debug=$([ ${operation} == true ] && echo + || echo -)
  local new_value=$([ ${operation} == true ] && \
    (
      new_value=$((${BL_CURR_BR_VAL} + ${BL_10PERC}))
      [ ${new_value} -gt ${BL_MAX_BR_VAL} ] && new_value=${BL_MAX_BR_VAL}
      echo ${new_value}
    ) || \
    (
      new_value=$((${BL_CURR_BR_VAL} - ${BL_10PERC}))
      [ ${new_value} -lt ${BL_MIN_BR_VAL} ] && new_value=${BL_MIN_BR_VAL}
      echo ${new_value}
    ))
    # Update brightness
    echo "Updating brightness by: ${debug}${new_value}"
    echo ${new_value} >| ${BL_CURR_BR}
}

do_main(){
  OPTSTRING=":IDRhU:L:"
  while getopts ${OPTSTRING} opt; do
    case ${opt} in
      I) do_update_brightness true;;
      D) do_update_brightness false;;
      R) do_read_brightness ;;
      U) do_update_brightness_by_val true ${OPTARG};;
      L) do_update_brightness_by_val false ${OPTARG} ;;
      h) usage ;;
      ?)
        echo "Invalid option: -${OPTARG}."
        usage
        exit 1
        ;;
    esac
  done
}

# Make sure the file is being executed and not sourced
if [ "$0" = "$BASH_SOURCE" ] ; then
  [ ${#} -eq 0 ] && usage && exit 1
  do_main $@
fi
