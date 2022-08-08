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

main() {
  # Stable
  ## Main machine types to match production systems
  "${SCRIPT_DIR}/build-vbox.bash" "bare" "stable"
  "${SCRIPT_DIR}/build-vagrantVbox.bash" "bare" "stable"

  # Testing
  ## Main machine types to match production systems
  "${SCRIPT_DIR}/build-vbox.bash" "bare" "testing"
  "${SCRIPT_DIR}/build-vagrantVbox.bash" "bare" "testing"

  # Run clean at the end
  "${SCRIPT_DIR}/clean.bash"
}

main
