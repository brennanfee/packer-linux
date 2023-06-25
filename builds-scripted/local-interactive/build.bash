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

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# END Bash strict mode

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../../script-tools.bash"

## Defaults
OS="debian"
DISK_CONFIG="single"
HELP="false"

show_help() {
  if [[ "${HELP}" == "false" ]]; then
    print_warning "Incorrect parameters or options provided."
    blank_line
  fi

  print_status "build Help"
  blank_line
  print_status "There is two parameters available: "
  blank_line
  print_status "  build <os> <disk configuration>"
  blank_line
  print_status "Basic usage:"
  blank_line
  print_status "Values can be omitted from the right toward the left of the options. An omitted option accepts the default for that option.  The options are ordered in order of importance and most common usage."
  blank_line
  print_status "  OS: Can be 'debian', 'ubuntu', or 'arch' for the Debian, Ubuntu, or Arch scripts. The default value is 'debian'.  At present the debian and ubuntu scripts are the same script."
  print_status "  Disk Configuration: Can be either 'single' or 'multi' for a single or multi-disk configuration. The default value is 'single'."
  blank_line

  if [[ "${HELP}" == "false" ]]; then
    exit 1
  else
    exit 0
  fi
}

ARGS=$(getopt --options h --longoptions "help" -- "$@")

# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
  show_help
fi

eval set -- "${ARGS}"
unset ARGS

while true; do
  case "$1" in
  '-h' | '--help')
    HELP="true"
    show_help
    ;;
  '--')
    shift
    break
    ;;
  *)
    error_msg "Unknown option: $1"
    ;;
  esac
done

ARG_COUNT=1
for arg; do
  case "${ARG_COUNT}" in
  1)
    OS=$(echo "${arg}" | tr "[:upper:]" "[:lower:]")
    ;;
  2)
    DISK_CONFIG=$(echo "${arg}" | tr "[:upper:]" "[:lower:]")
    ;;
  3)
    break
    ;;
  *)
    error_msg "Internal Argument Error"
    ;;
  esac
  ARG_COUNT=$((ARG_COUNT + 1))
done

verify_inputs() {
  local supported_disk_configs=("single" "multi")
  local supported_oses=("debian" "ubuntu" "arch")

  get_exit_code contains_element "${DISK_CONFIG}" "${supported_disk_configs[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for disk configuration '${DISK_CONFIG}', use 'single' or 'multi'"
  fi

  get_exit_code contains_element "${OS}" "${supported_oses[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for OS '${OS}', use 'debian', 'ubuntu', or 'arch'"
  fi
}

print_config() {
  print_info "Virtualization Type: VirtualBox"
  print_info "OS: ${OS}"
  print_info "Disk Config: ${DISK_CONFIG}"
}

main() {
  verify_inputs
  print_config

  local build_config="virtualbox-iso.local-vbox-interactive-bare"

  local vars_disk_config_file="${SCRIPT_DIR}/vars-disk-${DISK_CONFIG}.pkrvars.hcl"
  local vars_os_file="${SCRIPT_DIR}/vars-os-${OS}.pkrvars.hcl"

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run packer
  packer build -var-file="${vars_disk_config_file}" \
    -var-file="${vars_os_file}" \
    -only="${build_config}" "${SCRIPT_DIR}"
}

main "$@"
