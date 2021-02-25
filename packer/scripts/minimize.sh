#!/usr/bin/env bash

# Bash "strict" mode
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true
if ! $SOURCED; then
  set -uo pipefail
  shopt -s extdebug
  IFS=$'\n\t'
fi

if command -v apt-get &> /dev/null
then
  echo "Clean up Apt"
  apt-get -y -q autoremove
  apt-get -y -q clean
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

echo "Write zeros"
dd if=/dev/zero of=/junk bs=1M 2> /dev/null
sync
rm -f /junk

sync
