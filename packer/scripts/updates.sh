#!/usr/bin/env bash

# Bash "strict" mode
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true
if ! $SOURCED; then
  set -eEuo pipefail
  shopt -s extdebug
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
  IFS=$'\n\t'
fi

if command -v apt-get &> /dev/null
then
  DEBIAN_FRONTEND=noninteractive apt-get -y -q update
  DEBIAN_FRONTEND=noninteractive apt-get -y -q full-upgrade
fi

if command -v pacman &> /dev/null
then
  pacman -noconfirm -noprogressbar -Syyu
fi

## Reboot
systemctl reboot
