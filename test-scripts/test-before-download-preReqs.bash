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

WORKING_DIR=$(pwd)
LOG="${WORKING_DIR}/install.log"

echo "BEFORE TEST SCRIPT: This script downloads some files to be used in other params.  It creates a local encryption key and a local 'after' script file." >> "${LOG}"

wget -O "/home/user/test-after-script.py" "https://raw.githubusercontent.com/brennanfee/packer-linux/main/test-scripts/test-after-script.py"

wget -O "/home/user/test-encryption.key" "https://raw.githubusercontent.com/brennanfee/packer-linux/main/test-scripts/test-encryption.key"
