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
EXIT_CODE="0"

## Defaults
CONFIG="bare"
EDITION="stable"
ENCRYPTED="false"
DEBUG="false"
HELP="false"

show_help() {
  if [[ "${HELP}" == "false" ]]; then
    print_warning "Incorrect parameters or options provided."
    print_blank_line
  fi

  print_status "build Help"
  print_blank_line
  print_status "There are two parameters available: "
  print_blank_line
  print_status "  build [options] <os edition> <configuration>"
  print_blank_line
  print_status "Basic usage:"
  print_blank_line
  print_status "Values can be omitted from the right toward the left of the options. An omitted option accepts the default for that option.  The options are ordered in order of importance and most common usage."
  print_blank_line
  print_status "  OS Edition: Can be 'stable', 'backports', or 'testing' for Debian or 'lts', 'ltsedge' and 'rolling' for Ubuntu.  Each refers to the branch of OS you want to install.  The default value is 'stable' ('lts' for Ubuntu')."
  print_status "  Configuration: This is the machine configuration.  In this local test location only 'bare' and 'bios' are supported.  The default is 'bare'."
  print_blank_line
  print_status "A -e or --encrypted option can be included which will produce disks that are encrypted.  The default is to not encrypt the drives, which for virtual machines is usually preferred."
  print_blank_line
  print_status "A -d or --debug option can be included which will turn on debug mode."
  print_blank_line

  if [[ "${HELP}" == "false" ]]; then
    exit 1
  else
    exit 0
  fi
}

ARGS=$(getopt --options edh --longoptions "encrypted,debug,help" -- "$@")

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
    '-e' | '--encrypted')
      ENCRYPTED="true"
      shift
      continue
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
      EDITION=$(echo "${arg}" | tr "[:upper:]" "[:lower:]")
      ;;
    2)
      CONFIG="${arg}"
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
  local supported_configs=("bare" "bios")
  local supported_editions=("stable" "backports" "backportsdual" "testing" "lts" "ltsedge" "rolling")

  get_exit_code contains_element "${CONFIG}" "${supported_configs[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for config '${CONFIG}', use 'bare' or 'bios' ONLY"
  fi

  get_exit_code contains_element "${EDITION}" "${supported_editions[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for edition '${EDITION}', use 'stable', 'backports', 'testing', 'lts', 'ltsedge', or 'rolling'"
  fi
}

print_config() {
  print_info "Virtualization Type: VirtualBox"
  print_info "Configuration: ${CONFIG}"
  print_info "Edition: ${EDITION}"
  if [[ "${ENCRYPTED}" == "true" ]]; then
    print_info "Encrypted: Yes"
  else
    print_info "Encrypted: No"
  fi
  if [[ "${DEBUG}" == "true" ]]; then
    print_info "Debug: Enabled"
  else
    print_info "Debug: Disabled"
  fi
}

main() {
  verify_inputs
  print_config

  local build_config="virtualbox-iso.local-vbox-${CONFIG}"

  local vars_edition_file="${SCRIPT_DIR}/vars-edition-${EDITION}.pkrvars.hcl"

  local vars_debug="is_debug=0"
  if [[ "${DEBUG}" == "true" ]]; then
    vars_debug="is_debug=1"
  fi

  local vars_encrypted="auto_encrypt_disk=0"
  if [[ "${ENCRYPTED}" == "true" ]]; then
    vars_encrypted="auto_encrypt_disk=1"
  fi

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run packer
  packer build -var "${vars_debug}" -var "${vars_encrypted}" \
    -var-file="${vars_edition_file}" \
    -only="${build_config}" "${SCRIPT_DIR}"
}

main "$@"
