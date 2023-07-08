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

function check_root_with_error() {
  local check_root=0
  local user_id

  user_id=$(id -u)
  if [[ "${user_id}" == "0" ]]; then
    check_root=1
  fi

  if [[ "${check_root}" -eq 0 ]]; then
    local error_message=${1:-""}
    if [[ "${error_message}" == "" ]]; then
      error_message="ERROR!  You must execute this script as the 'root' user."
    fi
    local error_code=${2:-"1"}

    local T_COLS
    local text_red
    local text_reset

    text_red="$(tput setaf 1)"
    text_reset="$(tput sgr0)"
    T_COLS=$(tput cols)
    T_COLS=$((T_COLS - 1))

    # shellcheck disable=2154
    echo -e "${text_red}${error_message}${text_reset}\n" | fold -sw "${T_COLS}"
    exit "${error_code}"
  fi
}

main() {
  check_root_with_error ""

  local user_exists
  user_exists=$(getent passwd vagrant | wc -l || true)

  # Create the user if it doesn't exist
  if [[ ${user_exists} == "0" ]]; then
    echo 'Creating vagrant user'

    adduser --quiet --disabled-password --gecos "Vagrant" "vagrant"

    local passwd
    passwd=$(echo "vagrant" | openssl passwd -6 -stdin)
    usermod --password "${passwd}" "vagrant"

    user_exists="1"
  fi

  # Install ssh key
  if [[ ! -f /home/vagrant/.ssh/authorized_keys ]]; then
    echo 'Setting up vagrant users SSH'

    mkdir -p /home/vagrant/.ssh
    chown vagrant:vagrant /home/vagrant/.ssh
    chmod "0700" /home/vagrant/.ssh

    wget -nv --no-check-certificate -O /home/vagrant/.ssh/authorized_keys 'https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub'

    chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
    chmod "0644" /home/vagrant/.ssh/authorized_keys
  fi

  # Add vagrant user to passwordless sudo
  if [[ ! -f /etc/sudoers.d/vagrant ]]; then
    echo 'Setting up vagrant users sudo access'

    cat << EOF > /etc/sudoers.d/vagrant
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF

    chmod "0440" /etc/sudoers.d/vagrant
  fi

  # Add the user to some groups
  # _ssh is the new name for the ssh group going forward, but I attempt to add both (ssh, _ssh) just in case
  local groupsToAdd=(audio video plugdev netdev sudo ssh _ssh users data-user vboxsf)

  for groupToAdd in "${groupsToAdd[@]}"; do
    local group_exists
    group_exists=$(getent group "${groupToAdd}" | wc -l || true)
    if [[ "${group_exists}" -eq 1 ]]; then
      usermod -a -G "${groupToAdd}" "vagrant"
    fi
  done
}

main "$@"
