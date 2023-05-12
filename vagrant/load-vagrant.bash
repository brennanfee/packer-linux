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
# END Bash strict mode

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

text_reset="$(tput sgr0)"
text_green="$(tput setaf 2)"
text_yellow="$(tput setaf 3)"

function load_box() {
  local BOX_FILE="$1"
  if [[ -f "${SCRIPT_DIR}/../images/${BOX_FILE}.box" ]]
  then
    if vagrant box list | grep -q "${BOX_FILE}"
    then
      echo -e "${text_yellow}Removing old box - ${BOX_FILE}${text_reset}"
      vagrant box remove "${BOX_FILE}"
    fi

    echo -e "Adding box - ${BOX_FILE}"
    vagrant box add "${SCRIPT_DIR}/../images/${BOX_FILE}.box" --name "${BOX_FILE}"
  fi
}

function main() {
  local os_types=( "debian" "ubuntu" )
  local editions=( "stable" "testing" "backports" "lts" "ltsedge" "rolling" )
  local configurations=( "bare" )

  echo "Searching..."

  for os_type in "${os_types[@]}"; do
    for edition in "${editions[@]}"; do
      for config in "${configurations[@]}"; do

        local box_name="bfee-vagrantVbox-${os_type}-${edition}-${config}"

        load_box "${box_name}"

      done
    done
  done

  echo ""
  echo -e "${text_green}Complete${text_reset}"
}

main "$@"
