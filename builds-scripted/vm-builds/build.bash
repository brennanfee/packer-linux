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
EXIT_CODE=0

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../script_tools.bash"

# Defaults
VM_TYPES_STRING="vbox"
EDITIONS_STRING="stable"
CONFIGS_STRING="bare"
PRESERVE_IMAGE="false"
DEBUG="false"
HELP="false"

VM_TYPES=()
EDITIONS=()
CONFIGS=()

SUPPORTED_VM_TYPES=("vbox" "virtualbox" "vagrant-vbox" "vagrant-virtualbox")
SUPPORTED_EDITIONS=("stable" "testing" "backports" "backportsdual" "lts" "ltsedge" "rolling")
SUPPORTED_CONFIGS=("bare")

show_help() {
  if [[ "${HELP}" == "false" ]]; then
    print_warning "Incorrect parameters or options provided."
    blank_line
  fi

  print_status "build Help"
  blank_line
  print_status "There are two parameters available: "
  blank_line
  print_status "  build <vm type> <os\editions> <configuration>"
  blank_line
  print_status "Basic usage:"
  blank_line
  print_status "Values can be omitted from the right toward the left of the options." \
  " Multiple values can be passed by comma-separating the values, so 'vbox,vagrant-vbox'" \
  " both Virtualbox and the Vagrant Virtualbox flavor VMs.  Alternatively you can pass '*'" \
  " 'all' to indicate all of that type.  An omitted option accepts the default for that" \
  " option, which is 'all'."
  blank_line
  print_status "  VM Type: Can be 'vbox', 'virtualbox', 'vagrant-vbox', or 'vagrant-virtualbox'"
  print_status "  OS Edition: Can be either 'stable', 'testing', 'lts', 'ltsedge', or rolling'" \
  " and refers to the branch of Debian (for stable and testing) or Ubuntu (for lts,'" \
  " ltsedge, or rolling) to be installed."
  print_status "  Configuration: This is the machine configuration.  'bare', 'server'," \
  " 'desktop' are currently supported, later this will be just a pass-through with" \
  " no verification to any configuration script I decide to build."
  blank_line

  if [[ "${HELP}" == "false" ]]; then
    exit 1
  else
    exit 0
  fi

  exit 0
}

ARGS=$(getopt --options pdh --longoptions "preserve-image,debug,help" -- "$@")

# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
  show_help
fi

eval set -- "${ARGS}"
unset ARGS

while true; do
  case "$1" in
  '-h' | '--help')
    HELP="true"
    show_help
    ;;
  '-p' | '--preserve-image')
    PRESERVE_IMAGE="true"
    shift
    continue
    ;;
  '-d' | '--debug')
    DEBUG="true"
    shift
    continue
    ;;
  '--')
    shift
    break
    ;;
  *)
    error_msg "Unknown option: $1"
    ;;
  esac
done

ARG_COUNT=1
for arg; do
  case "${ARG_COUNT}" in
  1)
    VM_TYPES_STRING=$(echo "${arg}" | tr "[:upper:]" "[:lower:]")
    ;;
  2)
    EDITIONS_STRING=$(echo "${arg}" | tr "[:upper:]" "[:lower:]")
    ;;
  3)
    CONFIGS_STRING=$(echo "${arg}" | tr "[:upper:]" "[:lower:]")
    ;;
  4)
    break
    ;;
  *)
    error_msg "Internal Argument Error"
    ;;
  esac
  ARG_COUNT=$((ARG_COUNT + 1))
done

parse_vm_types() {
  local TEMP_ARRAY=()
  local VM_TYPES_TEMP=()
  if [[ "${VM_TYPES_STRING}" == "" ]]; then
    VM_TYPES_STRING="all"
  fi

  IFS=',' read -r -a TEMP_ARRAY <<<"${VM_TYPES_STRING}"
  for i in "${TEMP_ARRAY[@]}"; do
    if [[ "${i}" == "all" ]]; then
      VM_TYPES_TEMP=("${SUPPORTED_VM_TYPES[@]}")
    else
      get_exit_code contains_element "${i}" "${SUPPORTED_VM_TYPES[@]}"
      if [[ ! ${EXIT_CODE} == "0" ]]; then
        print_error "Invalid option for VM type '${i}', use one of 'vbox', 'virtualbox', 'vagrant-vbox' or 'vagrant-virtualbox'"
      fi

      VM_TYPES_TEMP+=("${i}")
    fi
  done

  # Canonicalize to just the two types 'vbox' and 'vagrantVbox'
  VM_TYPES_LIST=()
  for i in "${VM_TYPES_TEMP[@]}"; do
    case "${i}" in
    'vbox' | 'virtualbox')
      VM_TYPES_LIST+=('vbox')
      ;;
    'vagrant-vbox' | 'vagrant-virtualbox')
      VM_TYPES_LIST+=('vagrantVbox')
      ;;
    *)
      error_msg "Internal Argument Error: VM_TYPE"
      ;;
    esac
  done

  # Remove duplicates
  while IFS= read -r -d '' x; do
    VM_TYPES+=("${x}")
  done < <(printf "%s\0" "${VM_TYPES_LIST[@]}" | sort -uz || true)
}

parse_editions() {
  local TEMP_ARRAY=()
  local EDITIONS_TEMP=()
  if [[ "${EDITIONS_STRING}" == "" ]]; then
    EDITIONS_STRING="all"
  fi

  IFS=',' read -r -a TEMP_ARRAY <<<"${EDITIONS_STRING}"
  for i in "${TEMP_ARRAY[@]}"; do
    if [[ "${i}" == "all" ]]; then
      EDITIONS_TEMP=("${SUPPORTED_EDITIONS[@]}")
    elif [[ "${i}" == "debian" ]]; then
      EDITIONS_TEMP+=( "stable" "testing" "backports" "backportsdual" )
    elif [[ "${i}" == "ubuntu" ]]; then
      EDITIONS_TEMP+=( "lts" "ltsedge" "rolling" )
    else
      get_exit_code contains_element "${i}" "${SUPPORTED_EDITIONS[@]}"
      if [[ ! ${EXIT_CODE} == "0" ]]; then
        error_msg "Invalid option for edition '${i}', use one of 'stable', 'testing', 'backports', 'lts', 'ltsedge', 'rolling'."
      fi

      EDITIONS_TEMP+=("${i}")
    fi
  done
  # Remove duplicates
  while IFS= read -r -d '' x; do
    EDITIONS+=("${x}")
  done < <(printf "%s\0" "${EDITIONS_TEMP[@]}" | sort -uz || true)
}

parse_configs() {
  local TEMP_ARRAY=()
  local CONFIGS_TEMP=()
  if [[ "${CONFIGS_STRING}" == "" ]]; then
    CONFIGS_STRING="all"
  fi

  IFS=',' read -r -a TEMP_ARRAY <<<"${CONFIGS_STRING}"
  for i in "${TEMP_ARRAY[@]}"; do
    if [[ "${i}" == "*" || "${i}" == "all" ]]; then
      CONFIGS_TEMP=("${SUPPORTED_CONFIGS[@]}")
    else
      get_exit_code contains_element "${i}" "${SUPPORTED_CONFIGS[@]}"
      if [[ ! ${EXIT_CODE} == "0" ]]; then
        error_msg "Invalid option for edition '${i}', at present only 'bare' is supported."
      fi

      CONFIGS_TEMP+=("${i}")
    fi
  done

  # Remove duplicates
  while IFS= read -r -d '' x; do
    CONFIGS+=("${x}")
  done < <(printf "%s\0" "${CONFIGS_TEMP[@]}" | sort -uz || true)
}

print_config() {
  local vm_string
  local edition_string
  local config_string

  printf -v vm_string '%s,' "${VM_TYPES[@]}"
  printf -v edition_string '%s,' "${EDITIONS[@]}"
  printf -v config_string '%s,' "${CONFIGS[@]}"

  print_info "Virtualization Type: VirtualBox"

  print_info "VM Type: ${vm_string%,}"
  print_info "Edition: ${edition_string%,}"
  print_info "Configuration: ${config_string%,}"
  if [[ "${PRESERVE_IMAGE}" == "true" ]]; then
    print_info "Preserve Image: Yes"
  else
    print_info "Preserve Image: No"
  fi
  if [[ "${DEBUG}" == "true" ]]; then
    print_info "Debug Mode: On"
  else
    print_info "Debug Mode: Off"
  fi
}

main() {
  parse_vm_types
  parse_editions
  parse_configs

  print_config

  local vars_debug="is_debug=0"
  if [[ "${DEBUG}" == "true" ]]; then
    vars_debug="is_debug=1"
  fi

  local vars_preserve_image="preserve_image=false"
  if [[ "${PRESERVE_IMAGE}" == "true" ]]; then
    vars_preserve_image="preserve_image=true"
  fi

  for vm_type in "${VM_TYPES[@]}"; do
    for edition in "${EDITIONS[@]}"; do
      for config in "${CONFIGS[@]}"; do
        local build_config="virtualbox-iso.scripted-${vm_type}-${config}"

        # Run clean
        "${SCRIPT_DIR}/clean.bash"

        # Run packer
        if [[ "${vm_type}" == *"vagrant"* ]]; then
          packer build -var "${vars_debug}" -var "${vars_preserve_image}" \
            -var-file="${SCRIPT_DIR}/vars-edition-${edition}.pkrvars.hcl" \
            -var-file="${SCRIPT_DIR}/vars-vagrant.pkrvars.hcl" \
            -only="${build_config}" "${SCRIPT_DIR}"
        else
          packer build -var "${vars_debug}" -var "${vars_preserve_image}" \
            -var-file="${SCRIPT_DIR}/vars-edition-${edition}.pkrvars.hcl" \
            -only="${build_config}" "${SCRIPT_DIR}"
        fi
      done
    done
  done

  #TODO: Add error handling after the packer call

  echo ""
  print_success "Build Complete"
}

main "$@"
