#!/usr/bin/env bash

# Bash strict mode
([[ -n ${ZSH_EVAL_CONTEXT:-} && ${ZSH_EVAL_CONTEXT:-} =~ :file$ ]] ||
 [[ -n ${BASH_VERSION:-} ]] && (return 0 2>/dev/null)) && SOURCED=true || SOURCED=false
if ! ${SOURCED}
then
  set -o errexit # same as set -e
  set -o nounset # same as set -u
  set -o errtrace # same as set -E
  set -o pipefail
  set -o posix
  #set -o xtrace # same as set -x, turn on for debugging

  shopt -s inherit_errexit
  shopt -s extdebug
  IFS=$(printf '\n\t')
fi
# END Bash scrict mode

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#echo -e "\e[93mThe SCRIPT_DIR - ${SCRIPT_DIR}\e[0m"

function load_box() {
  local BOX_FILE=$1
  if [[ -f "${SCRIPT_DIR}/../images/${BOX_FILE}.box" ]]
  then
    if vagrant box list | grep -q "${BOX_FILE}"
    then
      echo -e "\e[93mRemoving old box - ${BOX_FILE}\e[0m"
      vagrant box remove "${BOX_FILE}"
    fi

    echo -e "\e[93mAdding box - ${BOX_FILE}\e[0m"
    vagrant box add "${SCRIPT_DIR}/../images/${BOX_FILE}.box" --name "${BOX_FILE}"
  fi
}

load_box "bfee-vagrantVbox-debian-stable-bare"
load_box "bfee-vagrantVbox-debian-testing-bare"
#load_box "bfee-ubuntu-rolling-bare"
