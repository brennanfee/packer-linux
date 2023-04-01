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

echo "BEFORE SCRIPT: Hello from before (pre-req verify) script" >> "${LOG}"

# Verify that ripgrep was installed into the pre-installation environment
result="PASS"
if [[ $(dpkg-query -W -f='${Status}' "ripgrep" 2>/dev/null | grep -c "ok installed" || true) != "1" ]]
then
  result="FAIL"
fi
echo "${result}: Ripgrep installed into pre-installation environment" >> "${LOG}"

if [[ "${result}" == "FAIL" ]]
then
  exit 10
fi
