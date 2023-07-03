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
source "${SCRIPT_DIR}/../../../script-tools.bash"

## Defaults
TEST_CASE="mtc01"
DEBUG=0
HELP="false"

show_help() {
  if [[ "${HELP}" == "false" ]]; then
    print_warning "Incorrect parameters or options provided."
    blank_line
  fi

  #TODO: Add help

  if [[ "${HELP}" == "false" ]]; then
    exit 1
  else
    exit 0
  fi
}

ARGS=$(getopt --options dh --longoptions "debug,help" -- "$@")

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
      TEST_CASE=$(echo "${arg}" | tr "[:upper:]" "[:lower:]")
      ;;
    2)
      break
      ;;
    *)
      error_msg "Internal Argument Error"
      ;;
  esac
  ARG_COUNT=$((ARG_COUNT + 1))
done

print_config() {
  print_info "Virtualization Type: VirtualBox"
  print_info "Test Case: ${TEST_CASE}"
  if [[ "${DEBUG}" == "true" ]]; then
    print_info "Debug Mode: On"
  else
    print_info "Debug Mode: Off"
  fi
}

main() {
  print_config

  local vars_debug="is_debug=0"
  if [[ "${DEBUG}" == "true" ]]; then
    vars_debug="is_debug=1"
  fi

  local vars_preserve_image="preserve_image=true"

  local vars_test_case_config_file
  vars_test_case_config_file="mtc01_singleDiskProvidedPassword.bash"
  if [[ "${TEST_CASE}" == "mtc02" ]]; then
    vars_test_case_config_file="mtc02_multiDiskProvidedPassword.bash"
  fi

  local vars_test_case_overrides
  if [[ -f "${SCRIPT_DIR}/vars-${TEST_CASE}.pkrvars.hcl" ]]; then
    vars_test_case_overrides="${SCRIPT_DIR}/vars-${TEST_CASE}.pkrvars.hcl"
  else
    vars_test_case_overrides="${SCRIPT_DIR}/../test-variables/vars-noop.pkrvars.hcl"
  fi

  local build_config="virtualbox-iso.test-vbox-manual-bare"

  # Run clean
  "${SCRIPT_DIR}/../clean.bash"

  # Run packer
  packer build -var "${vars_debug}" \
    -var "${vars_preserve_image}" \
    -var "test_case_config_file=${vars_test_case_config_file}" \
    -var-file="${vars_test_case_overrides}" \
    -only="${build_config}" "${SCRIPT_DIR}/.."

  EXIT_CODE=$?
  if [[ "${EXIT_CODE}" -ne 0 ]]; then
    error_msg "${TEST_CASE}: Packer run did not complete. ${EXIT_CODE}" 99
  fi
}

main "$@"
