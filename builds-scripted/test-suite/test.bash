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
EXIT_CODE=0

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../../script-tools.bash"

## Defaults
TEST_CASE="tc01"
PRESERVE_IMAGE="false"
DEBUG="false"
REPORT="false"
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

ARGS=$(getopt --options pdrh --longoptions "preserve-image,debug,report,help" -- "$@")

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
  '-p' | '--preserve-image')
    PRESERVE_IMAGE="true"
    shift
    continue
    ;;
  '-d' | '--debug')
    DEBUG="true"
    shift
    continue
    ;;
  '-r' | '--report')
    REPORT="true"
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

write_report() {
  if [[ "${REPORT}" == "true" ]]; then
    echo "${1}" >>"${SCRIPT_DIR}/test-report.txt"
  fi
}

error_msg_and_write() {
  write_report "${TEST_CASE}:FAIL"
  write_report "${1}"
  error_msg "${1}" "${2:-}"
}

verify_source_iso() {
  local supported_sources=("debian" "ubuntu" "bios")

  get_exit_code contains_element "${1}" "${supported_sources[@]}"
  if [[ ! "${EXIT_CODE}" == "0" ]]; then
    error_msg_and_write "${TEST_CASE}: Invalid option for source ISO '${1}', use 'debian', 'ubuntu', or 'bios' ONLY." 10
  fi
}

print_config() {
  print_info "Virtualization Type: VirtualBox"
  print_info "Test Case: ${TEST_CASE}"
  if [[ "${PRESERVE_IMAGE}" == "true" ]]; then
    print_info "Preserve Image: Yes"
  else
    print_info "Preserve Image: No"
  fi
  if [[ "${DEBUG}" == "true" ]]; then
    print_info "Debug Mode: On"
  else
    print_info "Debug Mode: Off"
  fi
  if [[ "${REPORT}" == "true" ]]; then
    print_info "Report Mode: On"
  else
    print_info "Report Mode: Off"
  fi
}

main() {
  print_config

  write_report "---- ${TEST_CASE} ----"

  local vars_debug="is_debug=0"
  if [[ "${DEBUG}" == "true" ]]; then
    vars_debug="is_debug=1"
  fi

  local vars_preserve_image="preserve_image=false"
  if [[ "${PRESERVE_IMAGE}" == "true" ]]; then
    vars_preserve_image="preserve_image=true"
  fi

  local vars_test_case_config_file
  vars_test_case_config_file="$(find "${SCRIPT_DIR}/test-configs" -iname "${TEST_CASE}*.bash" | sort | head -n 1 | sed "s/.*\///" || true)"
  if [[ ! -f "${SCRIPT_DIR}/test-configs/${vars_test_case_config_file}" ]]; then
    error_msg_and_write "${TEST_CASE}: Unable to find test case configuration script." 11
  fi

  local vars_test_case_verification_script
  vars_test_case_verification_script="$(find "${SCRIPT_DIR}/test-verifications" -iname "${TEST_CASE}*.bash" | sort | head -n 1 | sed "s/.*\///" || true)"
  if [[ ! -f "${SCRIPT_DIR}/test-verifications/${vars_test_case_verification_script}" ]]; then
    vars_test_case_verification_script="noop.bash"
  fi

  local vars_test_case_overrides
  if [[ -f "${SCRIPT_DIR}/test-variables/vars-${TEST_CASE}.pkrvars.hcl" ]]; then
    vars_test_case_overrides="${SCRIPT_DIR}/test-variables/vars-${TEST_CASE}.pkrvars.hcl"
  else
    vars_test_case_overrides="${SCRIPT_DIR}/test-variables/vars-noop.pkrvars.hcl"
  fi

  ## TEST_SOURCE_ISO=debian
  local source_iso
  source_iso=$(grep 'TEST_SOURCE_ISO' "${SCRIPT_DIR}/test-configs/${vars_test_case_config_file}" | cut -d= -f2)
  if [[ "${source_iso}" == "" ]]; then
    error_msg_and_write "${TEST_CASE}: Unable to determine test source ISO. Check test case configuration script." 12
  fi

  verify_source_iso "${source_iso}"
  print_info "Source ISO: ${source_iso}"

  local build_config="virtualbox-iso.test-vbox-${source_iso}-bare"

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run packer
  packer build -var "${vars_debug}" \
    -var "${vars_preserve_image}" \
    -var "test_case_config_file=${vars_test_case_config_file}" \
    -var "test_case_verification_script=${vars_test_case_verification_script}" \
    -var-file="${vars_test_case_overrides}" \
    -only="${build_config}" "${SCRIPT_DIR}"

  EXIT_CODE=$?
  if [[ "${EXIT_CODE}" -ne 0 ]]; then
    error_msg_and_write "${TEST_CASE}: Packer run did not complete. ${EXIT_CODE}" 99
  fi

  # Examine the test-results.txt file
  if [[ ! -f "${SCRIPT_DIR}/test-results.txt" ]]; then
    error_msg_and_write "${TEST_CASE}: Test results file not found." 13
  fi

  if [[ "${REPORT}" == "true" ]]; then
    awk -v tc="  ${TEST_CASE}: " '{print tc $0}' "${SCRIPT_DIR}/test-results.txt" >>"${SCRIPT_DIR}/test-report.txt"
  fi

  total_tests=$(grep -c -P '^PASS:|^FAIL:' "${SCRIPT_DIR}/test-results.txt" || true)
  failed_tests=$(grep -c -P '^FAIL:' "${SCRIPT_DIR}/test-results.txt" || true)

  if [[ ${failed_tests} -gt 0 ]]; then
    error_msg_and_write "${TEST_CASE}: ${failed_tests} tests failed out of ${total_tests} total tests." 14
  else
    write_report "${TEST_CASE}:PASS"
    local msg="${TEST_CASE}: All ${total_tests} tests passed."
    write_report "${msg}"
    print_success "${msg}"
  fi
}

main "$@"
