#!/usr/bin/env bash
# Bash strict mode
([[ -n ${ZSH_EVAL_CONTEXT:-} && ${ZSH_EVAL_CONTEXT:-} =~ :file$ ]] ||
 [[ -n ${BASH_VERSION:-} ]] && (return 0 2>/dev/null)) && SOURCED=true || SOURCED=false
if ! ${SOURCED}
then
  set -o errexit # same as set -e
  set -o nounset # same as set -u
  set -o errtrace # same as set -E
  set -o pipefail
  set -o posix
  #set -o xtrace # same as set -x, turn on for debugging

  shopt -s inherit_errexit
  shopt -s extdebug
  IFS=$(printf '\n\t')
fi
# END Bash scrict mode

# Must be root
cur_user=$(id -u)
if [[ ${cur_user} -ne 0 ]]
then
  echo -e "$(tput setaf 1 || true)ERROR! You must execute this script as the 'root' user.$(tput sgr0 || true)\n"
  exit 1
fi
unset cur_user

TEST_CASE="$(basename "${BASH_SOURCE[0]}" | cut -c -4)"

DPKG_ARCH=$(dpkg --print-architecture) # Something like amd64, arm64
UEFI=0

detect_if_eufi() {
  local vendor
  vendor=$(cat /sys/class/dmi/id/sys_vendor)
  if [[ "${vendor}" == 'Apple Inc.' ]] || [[ "${vendor}" == 'Apple Computer, Inc.' ]]
  then
    modprobe -r -q efivars || true # if MAC
  else
    modprobe -q efivarfs || true # all others
  fi

  if [[ -d "/sys/firmware/efi/" ]]
  then
    ## Mount efivarfs if it is not already mounted
    if [[ ! -d "/sys/firmware/efi/efivars" ]]
    then
      mount -t efivarfs efivarfs /sys/firmware/efi/efivars
    fi
    UEFI=1
  else
    UEFI=0
  fi
}

echo "Initializing test results file"
TEST_FILE="/srv/test-results.txt"
echo "TEST CASE: ${TEST_CASE}" | tee -a "${TEST_FILE}"

echo "Running tests..."
failed_tests=0
total_tests=0

# Verify this is a BIOS installation
detect_if_eufi
((total_tests=total_tests+1))
result="PASS"
if [[ "${UEFI}" != 0 ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: BIOS Setup" | tee -a "${TEST_FILE}"

# Verify the target OS is debian
((total_tests=total_tests+1))
result="PASS"
temp=$(lsb_release -i -s | tr "[:upper:]" "[:lower:]" || true)
if [[ "${temp}" != "debian" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Target OS" | tee -a "${TEST_FILE}"

# Verify the edition is stable
((total_tests=total_tests+1))
result="PASS"
temp=$(head -n 1 /etc/apt/sources.list | cut -d' ' -f 3 || true)
if [[ "${temp}" != "stable" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: OS Edition" | tee -a "${TEST_FILE}"

# Verify the kernel installed is the stable kernel
#TODO: Fix this, this tests that the package is installed but does not verify from where
((total_tests=total_tests+1))
result="PASS"
temp=$(dpkg-query -W -f='${Status}' "linux-image-${DPKG_ARCH}" 2>/dev/null | grep -c "ok installed" || true)
if [[ "${temp}" -eq 0 ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Kernel Edition" | tee -a "${TEST_FILE}"

# Hostname was auto-generated
((total_tests=total_tests+1))
result="PASS"
if [[ $(hostname -s | grep -P '^debian-\d{1,5}$' || true) == "" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Hostname" | tee -a "${TEST_FILE}"

# Domain 'mydomain.test' was used
((total_tests=total_tests+1))
result="PASS"
if [[ $(hostname -d || true) != "mydomain.test" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Domain" | tee -a "${TEST_FILE}"

# Check multi disk system
((total_tests=total_tests+1))
result="PASS"
if [[ $(lsblk -nd -oNAME,RO | awk '/0$/ {print $1}' | grep -cv '^sr' || true) != "2" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Single Disk System" | tee -a "${TEST_FILE}"

# Only the smallest disk was used for setup
((total_tests=total_tests+1))
result="PASS"
if [[ $(blkid | cut -d: -f 1 | grep -c /dev/sdb || true) != "0" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Second Disk NOT used" | tee -a "${TEST_FILE}"

# Verify we did not encrypt any drive
((total_tests=total_tests+1))
result="PASS"
if [[ $(wc -l /etc/crypttab | cut -d' ' -f 1 || true) != "1" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Not Encrypted" | tee -a "${TEST_FILE}"

# Check root account not disabled
((total_tests=total_tests+1))
result="PASS"
if [[ $(passwd -S root | cut -d' ' -f 2 || true) != "P" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Root enabled" | tee -a "${TEST_FILE}"

# Validate no user was created (no user 1000)
((total_tests=total_tests+1))
result="PASS"
if [[ $(cut -d: -f 3 /etc/passwd | grep -c 1000 || true) != "0" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: No Test User Created" | tee -a "${TEST_FILE}"

# Validate the root password is "thisIsRoot"
((total_tests=total_tests+1))
result="PASS"
attempt=$(echo 'thisIsRoot' | su -c "echo hello" root)
if [[ "${attempt}" == "" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
unset attempt
echo "${result}: Root Password Verified" | tee -a "${TEST_FILE}"

# Data folder should exist
((total_tests=total_tests+1))
result="PASS"
if [[ ! -d "/data" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Data Folder should exist" | tee -a "${TEST_FILE}"

# Make sure default stamp location was used (/data because we turned that feature on)
((total_tests=total_tests+1))
result="PASS"
if [[ ! -f "/data/image_build_info" ]]
then
  ((failed_tests=failed_tests+1))
  result="FAIL"
fi
echo "${result}: Default Stamp Location Used" | tee -a "${TEST_FILE}"

# Results
echo "${TEST_CASE}: ${failed_tests} tests failed out of ${total_tests} total tests."
