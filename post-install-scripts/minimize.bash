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

# Must be root
cur_user=$(id -u)
if [[ ${cur_user} -ne 0 ]]
then
  echo "This script must be run as root."
  exit 1
fi
unset cur_user

main() {
  if command -v apt-get &> /dev/null
  then
    echo "Clean up Apt"
    DEBIAN_FRONTEND=noninteractive apt-get -y -q autoremove
    DEBIAN_FRONTEND=noninteractive apt-get -y -q clean
    DEBIAN_FRONTEND=noninteractive apt-get -y -q autoclean
  fi

  if command -v pacman &> /dev/null
  then
    echo "Clean up Pacman"
    paccache -rk 1
    pacman -Sc
  fi

  if command -v dnf &> /dev/null
  then
    echo "Clean up Dnf"
    dnf clean all
  fi

  if command -v zypper &> /dev/null
  then
    echo "Clean up Zypper"
    zypper clean -a
  fi

  if command -v eopkg &> /dev/null
  then
    echo "Clean up eopkg"
    eopkg remove-orphans
    eopkg dc
    solbuild dc -a
  fi

  sync
  fstrim -a
}

main
