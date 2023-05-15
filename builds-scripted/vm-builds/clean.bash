#!/usr/bin/env bash

# Bash strict mode
([[ -n ${ZSH_EVAL_CONTEXT:-} && ${ZSH_EVAL_CONTEXT:-} =~ :file$ ]] ||
  [[ -n ${BASH_VERSION:-} ]] && (return 0 2>/dev/null)) && SOURCED=true || SOURCED=false
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
source "${SCRIPT_DIR}/../script_tools.bash"

main() {
  # First remove the VM's if they exist
  local registered_vms
  registered_vms="$(VBoxManage list vms | cut -d" " -f 1)"

  local vm_types=("vbox" "vagrantVbox")
  local os_types=("debian" "ubuntu")
  local editions=("stable" "testing" "backports" "backportsdual" "lts" "ltsedge" "rolling")
  local configurations=("bare")

  for vm_type in "${vm_types[@]}"; do
    for os_type in "${os_types[@]}"; do
      for edition in "${editions[@]}"; do
        for config in "${configurations[@]}"; do
          local vm_to_check_for="bfee-${vm_type}-${os_type}-${edition}-${config}"
          local dir_to_check="output-scripted-${vm_type}-${config}"

          if [[ "${registered_vms}" == *"${vm_to_check_for}"* ]]; then
            print_warning "WARNING: Removing the '${vm_to_check_for}' VM"
            VBoxManage unregistervm "${vm_to_check_for}" --delete
          fi

          if [[ -d "${dir_to_check}" ]]; then
            print_warning "WARNING: Removing the '${dir_to_check}' directory"
            rm -rf "${dir_to_check}"
          fi
        done
      done
    done
  done

  if [[ -f "${SCRIPT_DIR}/packer-manifest.json" ]]; then
    print_warning "WARNING: Removing the packer manifest"
    rm "${SCRIPT_DIR}/packer-manifest.json"
  fi

  # Delete any vagrant boxes
  find "${SCRIPT_DIR}" -iname "*.box" -delete

  echo ""
  print_success "Clean Complete"
}

main
