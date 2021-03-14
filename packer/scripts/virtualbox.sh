#!/usr/bin/env bash

# Bash "strict" mode
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true
if ! $SOURCED; then
  set -eEuo pipefail
  shopt -s extdebug
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
  IFS=$'\n\t'
fi

distro=$(lsb_release -i -s | tr '[:upper:]' '[:lower:]')

if [ $distro = "debian" ]; then
  # Need to manually place the startup.nsh file so Debian can boot correctly
  if [ ! -f /boot/efi/startup.nsh ]; then
    echo "\EFI\debian\grubx64.efi" > /boot/efi/startup.nsh
  fi

  DEBIAN_FRONTEND=noninteractive apt-get install -y linux-headers-$(uname -r)
fi

### Install the guest additions using the ISO
# NOTE: Why the ISO?  In Debian the guest addition packages are no longer
# available and while Ubuntu offers them, this provides consistency.

# Get the ISO, this version uses the apt package (usually out of date)
#DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends virtualbox-guest-additions-iso

# Get the ISO, this version uses the virutalbox site (more up-to-date)
mkdir /usr/share/virtualbox
version=$(curl -LSs https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
curl -LSs -o /usr/share/virtualbox/VBoxGuestAdditions.iso "https://download.virtualbox.org/virtualbox/$version/VBoxGuestAdditions_$version.iso"

# Mount the ISO and run the install
mkdir /media/vb-additions
mount /usr/share/virtualbox/VBoxGuestAdditions.iso /media/vb-additions -o loop
/media/vb-additions/VBoxLinuxAdditions.run --nox11 || true
umount /media/vb-additions
rmdir /media/vb-additions
