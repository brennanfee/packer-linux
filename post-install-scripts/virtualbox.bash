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
  local user_id
  user_id=$(id -u)

  if [[ ${user_id} -ne 0 ]]; then
    local error_message=${1:=""}
    if [[ "${error_message}" == "" ]]; then
      error_message="ERROR!  You must execute this script as the 'root' user."
    fi
    local error_code=${2:="1"}

    local T_COLS
    T_COLS=$(tput cols)
    T_COLS=$((T_COLS - 1))

    # Only here for portability, this method can be copy/pasted from here to anywhere else
    local RED
    local RESET
    RED="$(tput setaf 1)"
    RESET="$(tput sgr0)"

    # shellcheck disable=2154
    echo -e "${RED}${error_message}${RESET}\n" | fold -sw "${T_COLS}"
    exit "${error_code}"
  fi
}

main() {
  check_root_with_error

  local in_virtualbox
  in_virtualbox=$(lspci | grep -c VirtualBox)

  if [[ ${in_virtualbox} -ge 1 ]]; then
    local distro
    distro=$(lsb_release -i -s | tr '[:upper:]' '[:lower:]')

    DEBIAN_FRONTEND=noninteractive apt-get update

    if [[ "${distro}" = "debian" ]]; then
      # Need to ensure the linux headers are installed so it can compile the module
      DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends linux-image-amd64 linux-headers-amd64

      # If a UEFI install, fix the EFI boot
      if [[ -d "/boot/efi/" ]]; then
        if [[ ! -f "/boot/efi/startup.nsh" ]]; then
          echo "FS0:" > /boot/efi/startup.nsh
          echo "\EFI\debian\grubx64.efi" >> /boot/efi/startup.nsh
        fi

        DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends efibootmgr

        if ! efibootmgr | grep -i -q '\* debian'; then
          efi_disk=$(lsblk -np -o PKNAME,MOUNTPOINT | grep -i "/boot/efi" | cut -d' ' -f 1)
          efi_device=$(lsblk -np -o PATH,MOUNTPOINT | grep -i "/boot/efi" | cut -d' ' -f 1)
          efi_part="$(udevadm info --query=property --name="${efi_device}" | grep -i ID_PART_ENTRY_NUM | cut -d= -f 2)"

          efibootmgr -c -d "${efi_disk}" -p "${efi_part}" -l '\EFI\debian\grubx64.efi' -L 'debian'
        fi
      fi
    fi

    ### Install build prerequisites
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
      --no-install-recommends build-essential dkms libxt6 libxmu6

    ### Install the guest additions using the ISO

    # NOTE: Why the ISO?  In Debian the guest addition packages are no longer available and while Ubuntu offers them, this provides consistency.  If this script is being used in a packer environment, then the guest additions uploaded by it will be used.  If not, the ISO will be downloaded automatically.

    # Determine if we need to download the ISO and do so if needed
    if [[ ! -f "${HOME}/VBoxGuestAdditions.iso" ]]; then
      # Figure out which version to download
      /usr/bin/wget --output-document "${HOME}/LATEST-STABLE.TXT" https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT
      local vb_version
      vb_version=$(cat "${HOME}/LATEST-STABLE.TXT")
      rm "${HOME}/LATEST-STABLE.TXT"

      # Download it
      local vb_url="https://download.virtualbox.org/virtualbox/${vb_version}/VBoxGuestAdditions_${vb_version}.iso"
      /usr/bin/wget --output-document "${HOME}/VBoxGuestAdditions.iso" "${vb_url}"
    fi

    # Mount the ISO and run the install
    mkdir /media/vb-additions
    mount -t iso9660 -o loop,ro "${HOME}/VBoxGuestAdditions.iso" /media/vb-additions
    /media/vb-additions/VBoxLinuxAdditions.run --nox11 || true
    umount /media/vb-additions
    rmdir /media/vb-additions
    rm "${HOME}/VBoxGuestAdditions.iso"

    # Can't use $USER as we are running this script as root/sudo
    local current_user
    current_user=$(logname)

    # Add user to the vboxsf group
    local group_exists
    group_exists=$(getent group vboxsf | wc -l || true)

    if [[ ${group_exists} == "1" ]]; then
      local usersToAdd=("${current_user}" vagrant)

      for userToAdd in "${usersToAdd[@]}"; do
        local user_exists
        user_exists=$(getent passwd "${userToAdd}" | wc -l || true)
        if [[ "${user_exists}" -eq 1 ]]; then
          usermod -a -G vboxsf "${userToAdd}"
        fi
      done
    fi
  fi
}

main "$@"
