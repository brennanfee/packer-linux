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
EXIT_CODE=0

CONFIG=""
EDITION=""
DISK_CONFIG=""
ENCRYPTED=""
VARS_FILE=""

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../script_tools.bash"

help() {
  print_status "build-vbox Help"
  blank_line
  print_status "There are three parameters available: "
  blank_line
  print_status "  build-vbox <configuration> <os edition> <disk configuration> <encrypted>"
  blank_line
  print_status "Basic usage:"
  blank_line
  print_status "Values can be omitted from the right toward the left of the options."`
    `" An omitted option accepts the default for that option.  The optins are ordered"`
    `" in order of importance and most common usage."
  blank_line
  print_status "  Configuration: This is the machine configuration.  'bare', 'server',"`
    `" 'desktop' are currently supported, later this will be just a pass-through with"`
    `" no verification to any configuration script I decide to build. The default is"`
    `" 'bare'."
  print_status "  OS Edition: Can be either 'stable' or 'testing' and refers to the "`
    `"branch of Debian.  The default value is 'stable'."
  print_status "  Disk Configuration: Can be either 'single' or 'multi' for a "`
    `"single or multi-disk configuration. The default value is 'single'."
  print_status "  Encrypted: Can only be the word 'encrypted' and when present "`
    `"will produce disks that are encrypted.  The default value is not to encrypt."
  blank_line

  exit 0
}

read_inputs() {
  CONFIG=$(echo "${1:-}" | tr "[:upper:]" "[:lower:]")
  EDITION="${2:-}"
  DISK_CONFIG=$(echo "${3:-}" | tr "[:upper:]" "[:lower:]")
  ENCRYPTED=$(echo "${4:-}" | tr "[:upper:]" "[:lower:]")
}

set_defaults() {
  if [[ "${CONFIG}" == "" ]]
  then
    CONFIG="bare"
  fi

  if [[ "${EDITION}" == "" ]]
  then
    EDITION="stable"
  fi

  if [[ "${DISK_CONFIG}" == "" ]]
  then
    DISK_CONFIG="single"
  fi

  if [[ "${ENCRYPTED}" != "encrypted" ]]
  then
    ENCRYPTED=""
  fi
}

verify_inputs() {
  local supported_editions=( "stable" "stableBackports" "testing" )
  local supported_disk_configs=( "single" "multi" )

  get_exit_code contains_element "${EDITION}" "${supported_editions[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]
  then
    error_msg "Invalid option for edition '${EDITION}', use 'stable', 'stableBackports', or 'testing'"
  fi

  get_exit_code contains_element "${DISK_CONFIG}" "${supported_disk_configs[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]
  then
    error_msg "Invalid option for disk configuration '${DISK_CONFIG}', use 'single' or 'multi'"
  fi
}

print_config() {
  print_info "Virtualization Type: VirtualBox"
  print_info "Configuration: ${CONFIG}"
  print_info "Edition: ${EDITION}"
  print_info "Disk Config: ${DISK_CONFIG}"
  if [[ ${ENCRYPTED} == "" ]]
  then
    print_info "Encrypted: No"
  else
    print_info "Encrypted: Yes"
  fi
}

determine_vars_file() {
  VARS_FILE="vars-${EDITION}"
  if [[ "${DISK_CONFIG}" == "single" ]]
  then
    VARS_FILE="${VARS_FILE}-single"
  else
    VARS_FILE="${VARS_FILE}-multiDisk"
  fi

  if [[ "${ENCRYPTED}" == "encrypted" ]]
  then
    VARS_FILE="${VARS_FILE}-encrypted"
  fi

  # Tack on the extension
  VARS_FILE="${VARS_FILE}.pkrvars.hcl"

  if [[ ! -f "${SCRIPT_DIR}/${VARS_FILE}" ]]
  then
    error_msg "Variable file '${VARS_FILE}' does not exist."
    exit 1
  fi

  print_info "Variable File: ${VARS_FILE}"
}

main() {
  if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]
  then
    help
  fi

  read_inputs "$@"
  set_defaults
  verify_inputs

  print_config
  determine_vars_file

  local build_config="virtualbox-iso.local-vbox-debian-${CONFIG}"

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run packer
  packer build -var-file="${SCRIPT_DIR}/${VARS_FILE}" \
    -only="${build_config}" "${SCRIPT_DIR}"
}

main "$@"
