#!/usr/bin/env bash

# Bash "strict" mode
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true
if ! $SOURCED; then
  set -eEuo pipefail
  shopt -s extdebug
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
  IFS=$'\n\t'
fi

distro=$(lsb_release -i -s)

if [ $distro = "Debian" ]; then
  # Need to manually place the startup.nsh file so Debian can boot correctly
  if [ ! -f /boot/efi/startup.nsh ]; then
    echo "\EFI\debian\grubx64.efi" > /boot/efi/startup.nsh
  fi
fi
