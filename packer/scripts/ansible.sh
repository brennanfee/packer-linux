#!/usr/bin/env bash

# Bash "strict" mode
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true
if ! $SOURCED; then
  set -uo pipefail
  shopt -s extdebug
  IFS=$'\n\t'
fi

distro=$(lsb_release -i -s)

# Verify needed default installs
if command -v apt-get &> /dev/null
then
  apt-get -y -q install wget curl lsb-release build-essential dkms sudo acl git python3-dev python3-setuptools python3-wheel python3-keyring python3-venv python3-pip
fi

# Need to force a re-install of pip to fix an issue on debian stable, shouldn't hurt on
# other distros
curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
/usr/bin/python3 get-pip.py
rm get-pip.py

# Update existing pip packages
/usr/bin/python3 -m pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 /usr/bin/python3 -m pip install -U

# Install Ansible
/usr/bin/python3 -m pip install ansible cryptography
