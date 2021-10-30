#!/usr/bin/env sh

# POSIX strict mode (may produce issues in sourced scenarios)
set -o errexit
set -o nounset
#set -o xtrace # same as set -x, turn on for debugging

IFS=$(printf '\n\t')
# END POSIX scrict mode

for file in ./debian-*.hcl; do
  packer build -force "${file}"
done
