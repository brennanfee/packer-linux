#!/usr/bin/env bash

# Bash "strict" mode
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true
if ! $SOURCED; then
  set -eEuo pipefail
  shopt -s extdebug
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
  IFS=$'\n\t'
fi

if (grep -q -i -E "^vagrant:" /etc/passwd) then
  echo 'Setting up vagrant user'

  # Install vagrant ssh key
  if [ ! -f /home/vagrant/.ssh/authorized_keys ]; then
    mkdir /home/vagrant/.ssh
    wget -nv --no-check-certificate -O /home/vagrant/.ssh/authorized_keys 'https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub'
    chown -R vagrant /home/vagrant/.ssh
    chmod -R go-rwsx /home/vagrant/.ssh
  fi

  # Add vagrant user to passwordless sudo
  if [ ! -f /etc/sudoers.d/vagrant ]; then
    echo 'Defaults:vagrant !requiretty' > /etc/sudoers.d/vagrant
    echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/vagrant
    chmod 440 /etc/sudoers.d/vagrant
  fi

  # Add the ssh group if it does not exist
  if ! (grep -q -i -E "^ssh:" /etc/group) then
    groupadd --system ssh
  fi

  # Add vagrant user to the ssh group
  usermod -a -G ssh vagrant

  # Add vagrant user to the virtualbox group
  if (grep -q -i -E "^vboxsf:" /etc/group) then
    usermod -a -G vboxsf vagrant
  fi
fi
