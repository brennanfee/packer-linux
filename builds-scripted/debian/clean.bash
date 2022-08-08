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

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
  # First remove the VM's if they exist
  local registered_vms
  registered_vms="$(VBoxManage list vms | cut -d" " -f 1)"

  local vms_to_check_for=( "local-vbox-debian-stable-bare" \
    "local-vbox-debian-testing-bare" "local-vagrantVbox-debian-stable-bare" \
    "local-vagrantVbox-debian-testing-bare" )

  for vm_to_check_for in "${vms_to_check_for[@]}"
  do
    if [[ "${registered_vms}" == *"${vm_to_check_for}"* ]]
    then
      echo "WARNING: Removing the '${vm_to_check_for}' VM"
      VBoxManage unregistervm "${vm_to_check_for}" --delete
    fi
  done

  local sources_to_check_for=( "local-vbox-debian-bare" \
    "local-vagrantVbox-debian-bare" )

  for source_name in "${sources_to_check_for[@]}"
  do
    local dir_to_check="${SCRIPT_DIR}/output-${source_name}"
    if [[ -d "${dir_to_check}" ]]
    then
      echo "WARNING: Removing the '${dir_to_check}' directory"
      rm -rf "${dir_to_check}"
    fi
  done

  if [[ -f "${SCRIPT_DIR}/packer-manifest.json" ]]
  then
    echo "WARNING: Removing the packer manifest"
    rm "${SCRIPT_DIR}/packer-manifest.json"
  fi

  # Delete any vagrant boxes
  find "${SCRIPT_DIR}" -iname "*.box" -delete
}

main
