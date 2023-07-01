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
source "${SCRIPT_DIR}/../../script-tools.bash"
EXIT_CODE="0"

## Defaults
OS="debian"
DISK_CONFIG="single"
DEBUG="false"
HELP="false"

show_help() {
  if [[ "${HELP}" == "false" ]]; then
    print_warning "Incorrect parameters or options provided."
    blank_line
  fi

  print_status "build Help"
  blank_line
  print_status "There are two parameters available: "
  blank_line
  print_status "  build <os> <disk configuration>"
  blank_line
  print_status "Basic usage:"
  blank_line
  print_status "Values can be omitted from the right toward the left of the options. An omitted option accepts the default for that option.  The options are ordered in order of importance and most common usage."
  blank_line
  print_status "  OS: Can be 'debian', 'ubuntu', or 'arch' for the Debian, Ubuntu, or Arch scripts. The default value is 'debian'.  At present the debian and ubuntu scripts are the same script."
  print_status "  Disk Configuration: Can be either 'single', 'dual', 'triple', or 'multi'.  'multi' is a synonym for 'dual'. The default value is 'single'."
  blank_line
  print_status "A -d or --debug option can be included which will turn on debug mode."
  blank_line

  if [[ "${HELP}" == "false" ]]; then
    exit 1
  else
    exit 0
  fi
}

ARGS=$(getopt --options hd --longoptions "help,debug" -- "$@")

# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
  show_help
fi

eval set -- "${ARGS}"
unset ARGS

while true; do
  case "$1" in
  '-h' | '--help' | '-?')
    HELP="true"
    show_help
    ;;
  '-d' | '--debug')
    DEBUG="true"
    shift
    continue
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
  local supported_disk_configs=("single" "dual" "triple" "multi")
  local supported_oses=("debian" "ubuntu" "arch")

  get_exit_code contains_element "${DISK_CONFIG}" "${supported_disk_configs[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for disk configuration '${DISK_CONFIG}', use 'single' or 'multi'"
  fi
  # Normalize "multi"
  if [[ "${DISK_CONFIG}" == "multi" ]]; then
    DISK_CONFIG="dual"
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
  if [[ "${DEBUG}" == "true" ]]; then
    print_info "Debug: Enabled"
  else
    print_info "Debug: Disabled"
  fi
}

main() {
  verify_inputs
  print_config

  local build_config="virtualbox-iso.local-vbox-interactive-debian"
  if [[ "${OS}" == "arch" ]]; then
    build_config="virtualbox-iso.local-vbox-interactive-arch"
  fi

  local vars_os_file="${SCRIPT_DIR}/vars-os-${OS}.pkrvars.hcl"

  local vars_disks="additional_disks = []"
  if [[ "${DISK_CONFIG}" == "dual" ]]; then
    vars_disks="additional_disks = [102400]"
  elif [[ "${DISK_CONFIG}" == "triple" ]]; then
    vars_disks="additional_disks = [102400, 122880]"
  fi

  local vars_debug="is_debug=0"
  if [[ "${DEBUG}" == "true" ]]; then
    vars_debug="is_debug=1"
  fi

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run packer
  packer build -var "${vars_debug}" -var "${vars_disks}" \
    -var-file="${vars_os_file}" \
    -only="${build_config}" "${SCRIPT_DIR}"
}

main "$@"
