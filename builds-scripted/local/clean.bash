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

  local supported_virtPlatforms=( "vbox" "vagrantVbox" )
  local supported_distros=( "debian" "ubuntu" )
  local supported_editions=( "stable" "backports" "testing" )
  local supported_build_configs=( "bare" )

  for virtPlatform_to_check in "${supported_virtPlatforms[@]}"
  do
    for distro_to_check in "${supported_distros[@]}"
    do
      for edition_to_check in "${supported_editions[@]}"
      do
        for build_to_check in "${supported_build_configs[@]}"
        do
          local vm_to_check_for="local-${virtPlatform_to_check}-${distro_to_check}-${edition_to_check}-${build_to_check}"
          local source_to_check_for="local-${virtPlatform_to_check}-${distro_to_check}-${build_to_check}"

          # Remove the vm
          if [[ "${registered_vms}" == *"${vm_to_check_for}"* ]]
          then
            echo "WARNING: Removing the '${vm_to_check_for}' VM"
            VBoxManage unregistervm "${vm_to_check_for}" --delete
          fi

          # Now the output folder
          local dir_to_check="${SCRIPT_DIR}/output-${source_to_check_for}"
          if [[ -d "${dir_to_check}" ]]
          then
            echo "WARNING: Removing the '${dir_to_check}' directory"
            rm -rf "${dir_to_check}"
          fi
        done
      done
    done
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
