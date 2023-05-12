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
source "${SCRIPT_DIR}/../script_tools.bash"

## Defaults
OS="debian"
HELP="false"

show_help() {
  if [[ "${HELP}" == "false" ]]; then
    print_warning "Incorrect parameters or options provided."
    blank_line
  fi

  print_status "run Help"
  blank_line
  print_status "There is one parameter available: "
  blank_line
  print_status "  build <os>"
  blank_line
  print_status "Basic usage:"
  blank_line
  print_status "Values can be omitted from the right toward the left of the options. An omitted option accepts the default for that option.  The options are ordered in order of importance and most common usage."
  blank_line
  print_status "  OS: Can be 'debian', 'ubuntu', or 'arch' for the Debian, Ubuntu, or Arch scripts. The default value is 'debian'.  At present the debian and ubuntu scripts are the same script."
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

verify_inputs() {
  local supported_oses=("debian" "ubuntu" "arch")

  get_exit_code contains_element "${OS}" "${supported_oses[@]}"
  if [[ ! ${EXIT_CODE} == "0" ]]; then
    error_msg "Invalid option for OS '${OS}', use 'debian', 'ubuntu', or 'arch'"
  fi
}

print_config() {
  print_info "Virtualization Type: VirtualBox"
  print_info "OS: ${OS}"
}

main() {
  verify_inputs
  print_config

  if [[ "${OS}" == "ubuntu" ]]; then
    OS="debian"
  fi

  local file=""
  case "${OS}" in
  debian)
    file="deb-install-interactive.bash"
    ;;
  arch)
    file="arch-install-interactive.bash"
    ;;
  *)
    error_msg "Invalid OS option: ${OS}"
    ;;
  esac

  local script_file="../../../linux-bootstraps/scripted-installer/${OS}/${file}"

  # Run clean
  "${SCRIPT_DIR}/clean.bash"

  # Run the script
  bash "${script_file}"
}

main "$@"
