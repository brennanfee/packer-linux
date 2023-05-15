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

### START: Print Functions

# Text modifiers
TEXT_RESET="$(tput sgr0)"
TEXT_BOLD="$(tput bold)"
TEXT_RED="$(tput setaf 1)"
TEXT_GREEN="$(tput setaf 2)"
TEXT_YELLOW="$(tput setaf 3)"

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
  echo -e "$1${TEXT_RESET}" | fold -sw "${T_COLS}"
}

print_info() {
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${TEXT_BOLD}$1${TEXT_RESET}" | fold -sw "${T_COLS}"
}

print_warning() {
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${TEXT_YELLOW}$1${TEXT_RESET}" | fold -sw "${T_COLS}"
}

print_success() {
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${TEXT_GREEN}$1${TEXT_RESET}" | fold -sw "${T_COLS}"
}

print_error() {
  local T_COLS
  T_COLS=$(tput cols)
  T_COLS=$((T_COLS - 1))
  echo -e "${TEXT_RED}$1${TEXT_RESET}" | fold -sw "${T_COLS}"
}

error_msg() {
  print_error "$1"
  if [[ ${2:-} != "" ]]; then
    exit "$2"
  else
    exit 1
  fi
}

### END: Print Functions

### START: Array Tools

get_exit_code() {
  EXIT_CODE=0
  # We first disable errexit in the current shell
  set +e
  (
    # Then we set it again inside a subshell
    set -e
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
  for e in "${@:2}"; do
    [[ ${e} == "$1" ]] && break
  done
}

### END: Array Tools
