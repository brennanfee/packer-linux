#!/usr/bin/env bash

# Bash strict mode
([[ -n ${ZSH_EVAL_CONTEXT:-} && ${ZSH_EVAL_CONTEXT:-} =~ :file$ ]] \
  || [[ -n ${BASH_VERSION:-} ]] && (return 0 2> /dev/null)) && SOURCED=true || SOURCED=false
if ! ${SOURCED}; then
  set -o errexit  # same as set -e
  set -o nounset  # same as set -u
  set -o errtrace # same as set -E
  set -o pipefail
  set -o posix
  #set -o xtrace # same as set -x, turn on for debugging

  shopt -s inherit_errexit
  shopt -s extdebug
  IFS=$(printf '\n\t')
fi
# END Bash strict mode

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../../script-tools.bash"

main() {
  # First remove the VM's if they exist
  local registered_vms
  registered_vms="$(VBoxManage list vms | cut -d" " -f 1)"

  local supported_platforms=("debian" "arch")

  for platform_to_check in "${supported_platforms[@]}"; do
    local vm_to_check_for="local-vbox-interactive-${platform_to_check}"
    local source_to_check_for="local-vbox-interactive-${platform_to_check}"

    # Remove the vm
    if [[ "${registered_vms}" == *"${vm_to_check_for}"* ]]; then
      echo "WARNING: Removing the '${vm_to_check_for}' VM"
      VBoxManage unregistervm "${vm_to_check_for}" --delete
    fi

    # Now the output folder
    local dir_to_check="${SCRIPT_DIR}/output-${source_to_check_for}"
    if [[ -d "${dir_to_check}" ]]; then
      echo "WARNING: Removing the '${dir_to_check}' directory"
      rm -rf "${dir_to_check}"
    fi
  done

  if [[ -f "${SCRIPT_DIR}/packer-manifest.json" ]]; then
    echo "WARNING: Removing the packer manifest"
    rm -f "${SCRIPT_DIR}/packer-manifest.json"
  fi

  # Exported config
  rm -f "${SCRIPT_DIR}/my-config.bash"

  echo ""
  print_success "Clean Complete"
}

main "$@"
