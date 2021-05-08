#!/usr/bin/env bash

# Bash "strict" mode
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true
if ! $SOURCED; then
  set -eEuo pipefail
  shopt -s extdebug
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
  IFS=$'\n\t'
fi

date | sudo tee /srv/vagrant_box_build_time
