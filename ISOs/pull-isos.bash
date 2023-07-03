#!/usr/bin/env bash

# Bash strict mode
([[ -n ${ZSH_EVAL_CONTEXT:-} && ${ZSH_EVAL_CONTEXT:-} =~ :file$ ]] ||
  [[ -n ${BASH_VERSION:-} ]] && (return 0 2>/dev/null)) && SOURCED=true || SOURCED=false
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
# END Bash strict mode

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../script-tools.bash"

# Defaults
FORCE=0

function pull_arch() {
  print_heading "Checking Arch..."
  local root_path="${SCRIPT_DIR}/arch"
  local iso="${root_path}/archlinux-x86_64.iso"
  local shafile="${root_path}/sha256sums.txt"
  local version_file="${root_path}/version.txt"

  wget -O "${shafile}.orig" "https://mirror.rackspace.com/archlinux/iso/latest/sha256sums.txt"
  # read version and sha from the downloaded shafile
  local version
  local sha
  version=$(sed -nr 's/.* archlinux-([0-9]{4}\.[0-9]{2}\.[0-9]{2}).*/\1/p' "${shafile}.orig")
  sha=$(grep -i -P 'archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-.*' "${shafile}.orig" | cut -d' ' -f 1)

  local shas_differ=0
  if [[ -f "${iso}" ]]; then
    local calc_sha
    print_cyan "Calculating SHA"
    calc_sha=$(shasum --algorithm 256 "${iso}" | cut -d' ' -f 1)
    if [[ "${sha}" != "${calc_sha}" ]]; then
      print_cyan "SHAs differ"
      shas_differ=1
    fi
  else
    print_cyan "ISO file is missing"
    shas_differ=1
  fi

  # Only download if we were asked to force download or if the sha's differ
  if [[ ${FORCE} -eq 1 || ${shas_differ} -eq 1 ]]; then
    print_cyan "Downloading ISO"
    wget -O "${iso}" "https://mirror.rackspace.com/archlinux/iso/${version}/archlinux-x86_64.iso"
    wget -O "${shafile}" "https://mirror.rackspace.com/archlinux/iso/${version}/sha256sums.txt"

    [[ -f "${version_file}" ]] && rm "${version_file}"
    echo "${version}" >>"${version_file}"

    print_success "ISO updated"
  else
    print_warning "Skipped updating ISO"
  fi
}

function pull_debian() {
  print_heading "Checking Debian..."
  local root_path="${SCRIPT_DIR}/debian"
  local iso="${root_path}/debian-live-amd64-standard.iso"
  local shafile="${root_path}/SHA256SUMS"
  local version_file="${root_path}/version.txt"

  wget -O "${shafile}.orig" "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/SHA256SUMS"
  # read version and sha from the downloaded shafile
  local version
  local sha
  version=$(sed -nr 's/.* debian-live-([0-9]{2}\.[0-9]{1,2}\.[0-9]{1,2})-amd64-standard.iso$/\1/p' "${shafile}.orig")
  sha=$(grep -i -P 'debian-live-([0-9]{2}\.[0-9]{1,2}\.[0-9]{1,2})-amd64-standard.iso$' "${shafile}.orig" | cut -d' ' -f 1)

  local shas_differ=0
  if [[ -f "${iso}" ]]; then
    local calc_sha
    print_cyan "Calculating SHA"
    calc_sha=$(shasum --algorithm 256 "${iso}" | cut -d' ' -f 1)
    if [[ "${sha}" != "${calc_sha}" ]]; then
      print_cyan "SHAs differ"
      shas_differ=1
    fi
  else
    print_cyan "ISO file is missing"
    shas_differ=1
  fi

  # Only download if we were asked to force download or if the sha's differ
  if [[ ${FORCE} -eq 1 || ${shas_differ} -eq 1 ]]; then
    print_cyan "Downloading ISO"
    wget -O "${iso}" "https://cdimage.debian.org/debian-cd/${version}-live/amd64/iso-hybrid/debian-live-${version}-amd64-standard.iso"

    [[ -f "${shafile}" ]] && rm "${shafile}"
    echo "${sha} debian-live-amd64-standard.iso" >>"${shafile}"

    [[ -f "${version_file}" ]] && rm "${version_file}"
    echo "${version}" >>"${version_file}"

    print_success "ISO updated"
  else
    print_warning "Skipped updating ISO"
  fi
}

function pull_ubuntu() {
  print_heading "Checking Ubuntu..."
  local root_path="${SCRIPT_DIR}/ubuntu"
  local iso="${root_path}/ubuntu-live-amd64-standard.iso"
  local shafile="${root_path}/SHA256SUMS"
  local version_file="${root_path}/version.txt"

  # NOTE: Will need to be updated upon any Ubuntu LTS release
  local lts_codename="jammy"

  wget -O "${shafile}.orig" "https://releases.ubuntu.com/${lts_codename}/SHA256SUMS"
  # read version and sha from the downloaded shafile
  local version
  local sha
  version=$(sed -nr 's/.* \*?ubuntu-([0-9]{2}\.[0-9]{2}(\.[0-9]{1})?)-live-server-amd64.iso$/\1/p' "${shafile}.orig")
  sha=$(grep -i -P 'ubuntu-([0-9]{2}\.[0-9]{2}(\.[0-9]{1})?)-live-server-amd64.iso$' "${shafile}.orig" | cut -d' ' -f 1)

  local shas_differ=0
  if [[ -f "${iso}" ]]; then
    local calc_sha
    print_cyan "Calculating SHA"
    calc_sha=$(shasum --algorithm 256 "${iso}" | cut -d' ' -f 1)
    if [[ "${sha}" != "${calc_sha}" ]]; then
      print_cyan "SHAs differ"
      shas_differ=1
    fi
  else
    print_cyan "ISO file is missing"
    shas_differ=1
  fi

  # Only download if we were asked to force download or if the sha's differ
  if [[ ${FORCE} -eq 1 || ${shas_differ} -eq 1 ]]; then
    print_cyan "Downloading ISO"
    wget -O "${iso}" "https://releases.ubuntu.com/${lts_codename}/ubuntu-${version}-live-server-amd64.iso"

    [[ -f "${shafile}" ]] && rm "${shafile}"
    echo "${sha} ubuntu-live-server-amd64.iso" >>"${shafile}"

    [[ -f "${version_file}" ]] && rm "${version_file}"
    echo "${version}" >>"${version_file}"

    print_success "ISO updated"
  else
    print_warning "Skipped updating ISO"
  fi
}

function spacer() {
  print_blank_line
  print_separator
}

function main() {
  pull_arch
  spacer
  pull_debian
  spacer
  pull_ubuntu
  spacer

  print_blank_line
  print_success "Complete"
}

main "$@"
