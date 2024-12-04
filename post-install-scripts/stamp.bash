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

function check_for_root() {
  # Must be root
  local cur_user
  cur_user=$(id -u)
  if [[ ${cur_user} -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
  fi
}

main() {
  check_for_root

  local stamp_path="/srv"
  if [[ -d "/data" ]]; then
    stamp_path="/data"
  fi

  local the_date
  the_date=$(date -Is)
  echo "Packer Build Time: ${the_date}" | sudo tee "${stamp_path}/image_build_info"

  if [[ -n "${PACKER_BUILD_NAME:-}" ]]; then
    echo "Packer Build Name: ${PACKER_BUILD_NAME}" | sudo tee -a "${stamp_path}/image_build_info"
  fi

  if [[ -n "${PACKER_BUILDER_TYPE:-}" ]]; then
    echo "Packer Builder Type: ${PACKER_BUILDER_TYPE}" | sudo tee -a "${stamp_path}/image_build_info"
  fi

  # Can't use $USER here because we are running this script as root
  local current_user
  current_user=$(logname)
  echo "Packer Installed User: ${current_user}" | sudo tee -a "${stamp_path}/image_build_info"

  local vbox_version
  if [[ -f "/home/${current_user}/.vbox_version" ]]; then
    vbox_version=$(cat "/home/${current_user}/.vbox_version")
    rm "/home/${current_user}/.vbox_version"
  elif [[ -f "/srv/.vbox_version" ]]; then
    vbox_version=$(sudo cat "/srv/.vbox_version")
    rm "/srv/.vbox_version"
  elif [[ -f "/srv/vbox_version" ]]; then
    vbox_version=$(sudo cat "/srv/vbox_version")
    rm "/srv/vbox_version"
  elif [[ -f "/usr/local/src/virtualbox-guest/vbox_version" ]]; then
    vbox_version=$(sudo cat "/usr/local/src/virtualbox-guest/vbox_version")
  fi

  if [[ -n "${vbox_version}" ]]; then
    echo "VirtualBox Version: ${vbox_version}" | sudo tee -a "${stamp_path}/image_build_info"
  fi

  if [[ ${stamp_path} == "/data" ]]; then
    local group_exists
    group_exists=$(getent group data-user | wc -l || true)
    if [[ ${group_exists} == "1" ]]; then
      chown root:data-user "${stamp_path}/image_build_info"
    else
      chown root:users "${stamp_path}/image_build_info"
    fi
  else
    local group_exists
    group_exists=$(getent group srv-user | wc -l || true)
    if [[ ${group_exists} == "1" ]]; then
      chown root:srv-user "${stamp_path}/image_build_info"
    else
      chown root:users "${stamp_path}/image_build_info"
    fi
  fi
  chmod g+rw "${stamp_path}/image_build_info"
}

main "$@"
