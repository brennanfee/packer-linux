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
# END Bash scrict mode

function check_for_root() {
  # Must be root
  local cur_user
  cur_user=$(id -u)
  if [[ ${cur_user} -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
  fi
}

main() {
  check_for_root

  if command -v apt-get &> /dev/null; then
    echo "Clean up Apt - Update"
    DEBIAN_FRONTEND=noninteractive apt-get -y -q update || true
    echo "Clean up Apt - Autoremove"
    DEBIAN_FRONTEND=noninteractive apt-get -y -q autoremove || true
    echo "Clean up Apt - Clean"
    DEBIAN_FRONTEND=noninteractive apt-get -y -q clean || true
    echo "Clean up Apt - AutoClean"
    DEBIAN_FRONTEND=noninteractive apt-get -y -q autoclean || true
  fi

  if command -v pacman &> /dev/null; then
    echo "Clean up Pacman"
    paccache -rk 1
    pacman -Sc
  fi

  if command -v dnf &> /dev/null; then
    echo "Clean up Dnf"
    dnf clean all
  fi

  if command -v zypper &> /dev/null; then
    echo "Clean up Zypper"
    zypper clean -a
  fi

  if command -v eopkg &> /dev/null; then
    echo "Clean up eopkg"
    eopkg remove-orphans
    eopkg dc
    solbuild dc -a
  fi

  echo "Syncing disks"
  sync || true
  echo "Calling fstrim"
  fstrim -a --quiet-unsupported || true

  echo "Finished minimize"
  exit 0
}

main
