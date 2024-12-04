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
EDITION="stable"
BUILD_TYPE="bare"
CONFIG="default"
DUAL_DISKS="false"
ENCRYPTED="false"
INTERACTIVE="false"
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
  print_status "  build [options] <os edition> <build type> (<configuration>)"
  print_blank_line
  print_status "Basic usage:"
  print_blank_line
  print_status "Values can be omitted from the right toward the left of the options. An omitted option accepts the default for that option.  The options are ordered in order of importance and most common usage."
  print_blank_line
  print_status "  OS Edition: Can be 'stable', 'backports', or 'testing' for Debian or 'lts', 'ltshwe', 'ltsedge' and 'rolling' for Ubuntu.  Each refers to the branch of OS you want to install.  The default value is 'stable' ('lts' for Ubuntu')."
  print_status "  Build Type: This is the end software configuration of the machine.  In this local test location only 'bare' and 'bios' are supported.  The default is 'bare'."
  print_status "  Configuration: This is the bootstrap configuration.  This is passed through to the bootstrap script.  The default is 'default'."
  print_blank_line
  print_status "A -d or --dual-disk option can be included which will produce a vim with two hard drives."
  print_blank_line
  print_status "A -e or --encrypted option can be included which will produce disks that are encrypted.  The default is to not encrypt the drives, which for virtual machines is usually preferred."
  print_blank_line
  print_status "A --debug option can be included which will turn on debug mode."
  print_blank_line

  if [[ "${HELP}" == "false" ]]; then
    exit 1
  else
    exit 0
  fi
}

ARGS=$(getopt --options edih --longoptions "encrypted,dual-disks,interactive,help,debug" -- "$@")

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
    '-d' | '--dual-disk' | '--dual-disks')
      DUAL_DISKS="true"
      shift
      continue
      ;;
    '-e' | '--encrypted')
      ENCRYPTED="true"
      shift
      continue
      ;;
    '-i' | '--interactive')
      INTERACTIVE="true"
      shift
      continue
      ;;
    '--debug')
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
      BUILD_TYPE="${arg}"
      ;;
    3)
      CONFIG="${arg}"
      ;;
    4)
      break
      ;;
    *)
      error_msg "Internal Argument Error"
      ;;
  esac
  ARG_COUNT=$((ARG_COUNT + 1))
done

verify_inputs() {
  local supported_editions=("stable" "backports" "backport" "testing" "lts" "ltshwe" "ltsedge" "rolling")
  local supported_build_types=("bare" "bios")

  get_exit_code contains_element "${EDITION}" "${supported_editions[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for edition '${EDITION}', use 'stable', 'backports', 'testing', 'lts', 'ltshwe', 'ltsedge', or 'rolling'."
  fi

  get_exit_code contains_element "${BUILD_TYPE}" "${supported_build_types[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for build type '${BUILD_TYPE}', use 'bare' or 'bios' ONLY"
  fi
}

print_config() {
  print_info "Virtualization Type: VirtualBox"
  print_info "Edition: ${EDITION}"
  print_info "Build Type: ${BUILD_TYPE}"
  print_info "Configuration: ${CONFIG}"
  if [[ "${DUAL_DISKS}" == "true" ]]; then
    print_info "Dual Disks: Yes"
  else
    print_info "Dual Disks: No"
  fi
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

  local build_file="virtualbox-iso.local-vbox-${BUILD_TYPE}"

  local os="debian"
  if [[ "${EDITION}" == "lts" || "${EDITION}" == "ltshwe" || "${EDITION}" == "ltsedge" ||
    "${EDITION}" == "rolling" ]]; then

    os="ubuntu"
  fi
  if [[ "${EDITION}" == "backport" ]]; then
    EDITION="backports"
  fi

  local vars_os="os=${os}"
  local vars_edition="edition=${EDITION}"
  local vars_username="username=root"
  local vars_password="password=${os}"
  local vars_config="config=${CONFIG}"

  if [[ "${CONFIG}" == "vagrant" ]]; then
    local vars_username="username=vagrant"
    local vars_password="password=vagrant"
  fi

  local vars_script_source="script_source=http://{{ .HTTPIP }}:{{ .HTTPPort }}/deb-install.bash"
  if [[ "${INTERACTIVE}" == "true" ]]; then
    local vars_script_source="script_source=http://{{ .HTTPIP }}:{{ .HTTPPort }}/deb-install-interactive.bash"
  fi

  local vars_disks="additional_disks=[]"
  local vars_flags="flags="
  if [[ "${DUAL_DISKS}" == "true" ]]; then
    vars_disks="additional_disks=[102400]"
    vars_flags="${vars_flags}--dual-disks "
  fi

  if [[ "${DEBUG}" == "true" ]]; then
    vars_flags="${vars_flags}--debug "
  fi

  if [[ "${ENCRYPTED}" == "true" ]]; then
    vars_flags="${vars_flags}--encrypt "
  fi

  if [[ "${INTERACTIVE}" == "true" ]]; then
    vars_flags="${vars_flags}--interactive"
  fi

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run packer
  packer build -var "${vars_os}" -var "${vars_edition}" \
    -var "${vars_username}" -var "${vars_password}" -var "${vars_disks}" \
    -var "${vars_script_source}" -var "${vars_config}" -var "${vars_flags}" \
    -only="${build_file}" "${SCRIPT_DIR}"
}

main "$@"
