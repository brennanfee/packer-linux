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

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../script_tools.bash"

## Defaults
PRESERVE_IMAGE="false"
DEBUG="false"
HELP="false"

show_help() {
  if [[ "${HELP}" == "false" ]]
  then
    print_warning "Incorrect parameters or options provided."
    blank_line
  fi

  #TODO: Add help

  if [[ "${HELP}" == "false" ]]
  then
    exit 1
  else
    exit 0
  fi
}

ARGS=$(getopt --options pdh --longoptions "preserve-image,debug,help" -- "$@")

# shellcheck disable=SC2181
if [[ $? -ne 0 ]]
then
  show_help
fi

eval set -- "${ARGS}"
unset ARGS

while true
do
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
    '--')
      shift
      break
      ;;
    *)
      error_msg "Unknown option: $1"
      ;;
  esac
done

main() {
  # Cleanup previous test-report
  if [[ -f "${SCRIPT_DIR}/test-report.txt" ]]
  then
    rm -f "${SCRIPT_DIR}/test-report.txt"
  fi

  local options="-r"
  if [[ "${DEBUG}" == "true" ]]
  then
    options="${options}d"
  fi

  if [[ "${PRESERVE_IMAGE}" == "true" ]]
  then
    options="${options}p"
  fi

  # Get the list of test cases
  readarray -t test_cases < <(find "${SCRIPT_DIR}/test-configs" -iregex '.*tc[0-9][0-9].*' | sed "s/.*\///" | cut -c -4 | sort -u || true)

  # Loop over them and run each one...
  for test_case in "${test_cases[@]}"
  do
    "${SCRIPT_DIR}"/test.bash "${options}" "${test_case}" || true
  done

  if [[ ! -f "${SCRIPT_DIR}/test-report.txt" ]]
  then
    error_msg "Test Suite Failed, test report file not created." 2
  fi

  # Process reports file results
  total_tests=$(grep -c -P '^[Tt][Cc]\d{2}:(PASS|FAIL)$' "${SCRIPT_DIR}/test-report.txt" || true)
  failed_tests=$(grep -c -P '^[Tt][Cc]\d{2}:FAIL$' "${SCRIPT_DIR}/test-report.txt" || true)
  if [[ ${failed_tests} -gt 0 ]]
  then
    error_msg "Test Suite Failed, ${failed_tests} test cases failed out of ${total_tests} total test cases." 3
  else
    print_success "Test Suite Complete, ALL TESTS PASSED!"
  fi
}

main "$@"
