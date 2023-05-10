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

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../script_tools.bash"

help() {
  print_status "build-vagrantVbox Help"
  blank_line
  print_status "There are three parameters available: "
  blank_line
  print_status "  build-vagrantVbox <os edition> <configuration>"
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
  blank_line

  exit 0
}

read_inputs() {
  EDITION=$(echo "${1:-}" | tr "[:upper:]" "[:lower:]")
  CONFIG=$(echo "${2:-}" | tr "[:upper:]" "[:lower:]")
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
}

verify_inputs() {
  local supported_editions=( "stable" "testing" "backports" )

  get_exit_code contains_element "${EDITION}" "${supported_editions[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]
  then
    error_msg "Invalid option for edition '${EDITION}', use 'stable' or 'testing'"
  fi

  local supported_configs=( "bare" )

  get_exit_code contains_element "${CONFIG}" "${supported_configs[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]
  then
    error_msg "Invalid option for edition '${CONFIG}', at present only 'bare' is supported."
  fi
}

print_config() {
  print_info "Virtualization Type: Vagrant (VirtualBox)"
  print_info "Edition: ${EDITION}"
  print_info "Configuration: ${CONFIG}"
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

  local build_config="virtualbox-iso.vagrantVbox-debian-${CONFIG}"

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run packer
  packer build -var-file="${SCRIPT_DIR}/vars-${EDITION}.pkrvars.hcl" \
    -var-file="${SCRIPT_DIR}/vars-vagrant.pkrvars.hcl" \
    -only="${build_config}" "${SCRIPT_DIR}"
}

main "$@"
