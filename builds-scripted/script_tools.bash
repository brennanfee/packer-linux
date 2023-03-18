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

### START: Print Functions

# Text modifiers
RESET="$(tput sgr0)"
BOLD="$(tput bold)"

print_line() {
  local T_COLS
  T_COLS=$(tput cols)
  printf "%${T_COLS}s\n" | tr ' ' '-'
  write_log_spacer
}

blank_line() {
  echo ""
}

print_status() {
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "$1${RESET}" | fold -sw "${T_COLS}"
}

print_info() {
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${BOLD}$1${RESET}" | fold -sw "${T_COLS}"
}

print_warning() {
  local YELLOW
  YELLOW="$(tput setaf 3)"
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${YELLOW}$1${RESET}" | fold -sw "${T_COLS}"
}

print_success() {
  local GREEN
  GREEN="$(tput setaf 2)"
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${GREEN}$1${RESET}" | fold -sw "${T_COLS}"
}

print_error() {
  local RED
  RED="$(tput setaf 1)"
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${RED}$1${RESET}\n" | fold -sw "${T_COLS}"
}

error_msg() {
  print_error "$1"
  exit 1
}

### END: Print Functions

### START: Array Tools

get_exit_code() {
  EXIT_CODE=0
  # We first disable errexit in the current shell
  set +e
  (
    # Then we set it again inside a subshell
    set -e;
    # ...and run the function
    "$@"
  )
  # shellcheck disable=2034
  EXIT_CODE=$?
  # And finally turn errexit back on in the current shell
  set -e
}

contains_element() {
  #check if an element exist in a string
  for e in "${@:2}"
  do
    [[ ${e} == "$1" ]] && break
  done
}

### END: Array Tools
