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
  local user_exists
  user_exists=$(getent passwd vagrant | wc -l || true)

  # Create the user if it doesn't exist
  if [[ ${user_exists} == "0" ]]
  then
    adduser --quiet --disabled-password --gecos "Vagrant" "vagrant"
    local passwd
    passwd=$(echo "vagrant" | openssl passwd -6 -stdin)
    usermod --password "${passwd}" "vagrant"

    # NOTE: I added _ssh as a group because it seems that Debian testing is currently not creating the standard ssh group but instead naming it _ssh, need to investigate further.
    groupsToAdd=(audio video plugdev netdev sudo ssh _ssh users data-user vboxsf)
    for groupToAdd in "${groupsToAdd[@]}"
    do
      group_exists=$(getent group "${groupToAdd}" | wc -l || true)
      if [[ ${group_exists} == "1" ]]
      then
        usermod -a -G "${groupToAdd}" "vagrant"
      fi
    done

    user_exists="1"
  fi

  echo 'Setting up vagrant user'

  # Install vagrant ssh key
  if [[ ! -f /home/vagrant/.ssh/authorized_keys ]]
  then
    mkdir -p /home/vagrant/.ssh
    wget -nv --no-check-certificate -O /home/vagrant/.ssh/authorized_keys 'https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub'
    chown -R vagrant /home/vagrant/.ssh
    chmod -R go-rwsx /home/vagrant/.ssh
  fi

  # Add vagrant user to passwordless sudo
  if [[ ! -f /etc/sudoers.d/vagrant ]]
  then
    cat << EOF > /etc/sudoers.d/vagrant
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF

    chmod 440 /etc/sudoers.d/vagrant
  fi

  # Add the user to some groups
  local groupsToAdd=(sudo ssh _ssh users data-user vboxsf)

  for groupToAdd in "${groupsToAdd[@]}"
  do
    local group_exists
    group_exists=$(getent group "${groupToAdd}" | wc -l || true)
    if [[ "${group_exists}" -eq 1 ]]
    then
      usermod -a -G "${groupToAdd}" "vagrant"
    fi
  done
}

main
