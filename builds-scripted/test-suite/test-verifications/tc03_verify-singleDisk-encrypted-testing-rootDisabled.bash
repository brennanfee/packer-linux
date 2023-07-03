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

# Must be root
cur_user=$(id -u)
if [[ ${cur_user} -ne 0 ]]; then
  echo -e "$(tput setaf 1 || true)ERROR! You must execute this script as the 'root' user.$(tput sgr0 || true)\n"
  exit 1
fi
unset cur_user

TEST_CASE="$(basename "${BASH_SOURCE[0]}" | cut -c -4)"

#DPKG_ARCH=$(dpkg --print-architecture) # Something like amd64, arm64

echo "Initializing test results file"
TEST_FILE="/srv/test-results.txt"
echo "TEST CASE: ${TEST_CASE}" | tee -a "${TEST_FILE}"

echo "Running tests..."
failed_tests=0
total_tests=0

# Verify the target OS is debian
((total_tests = total_tests + 1))
result="PASS"
temp=$(lsb_release -i -s | tr "[:upper:]" "[:lower:]" || true)
if [[ "${temp}" != "debian" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Target OS" | tee -a "${TEST_FILE}"

# Verify the edition is testing
((total_tests = total_tests + 1))
result="PASS"
temp=$(head -n 1 /etc/apt/sources.list | cut -d' ' -f 3 || true)
if [[ "${temp}" != "testing" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: OS Edition" | tee -a "${TEST_FILE}"

# Hostname is 'myhost'
((total_tests = total_tests + 1))
result="PASS"
if [[ $(hostname -s || true) != "myhost" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Hostname" | tee -a "${TEST_FILE}"

# No domain was used
((total_tests = total_tests + 1))
result="PASS"
if [[ $(hostname -d || true) != "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Domain" | tee -a "${TEST_FILE}"

# Timezone should be "American/Los_Angeles"
((total_tests = total_tests + 1))
result="PASS"
if [[ $(cat /etc/timezone || true) != "America/Los_Angeles" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Timezone Overriden" | tee -a "${TEST_FILE}"

# Check single disk system
((total_tests = total_tests + 1))
result="PASS"
if [[ $(lsblk -nd -oNAME,RO | awk '/0$/ {print $1}' | grep -cv '^sr' || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Single Disk Setup" | tee -a "${TEST_FILE}"

# Verify we did encrypt the drive
((total_tests = total_tests + 1))
result="PASS"
if [[ $(wc -l /etc/crypttab | cut -d' ' -f 1 || true) != "2" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Drive Encrypted" | tee -a "${TEST_FILE}"

# Verify root encryption key file
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f /boot/root.key ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Encryption key file" | tee -a "${TEST_FILE}"

# Validate we have a user "test"
((total_tests = total_tests + 1))
result="PASS"
if [[ $(getent passwd test || true) == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Test User Created" | tee -a "${TEST_FILE}"

# Check root account is disabled
((total_tests = total_tests + 1))
result="PASS"
if [[ $(passwd -S root | cut -d' ' -f 2 || true) != "L" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Root disabled" | tee -a "${TEST_FILE}"

# Validate the user password is "test"
((total_tests = total_tests + 1))
result="PASS"
attempt=$(echo 'test' | su -c "echo hello" test)
if [[ "${attempt}" == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
unset attempt
echo "${result}: User Password Verified" | tee -a "${TEST_FILE}"

# Data folder should exist
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -d "/data" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Data Folder should exist" | tee -a "${TEST_FILE}"

# Make sure stamp location override was used despite data folder, /xxx
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f "/xxx/image_build_info" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Overridden Stamp Location Used" | tee -a "${TEST_FILE}"

# Verify that ansible was installed for config management
((total_tests = total_tests + 1))
result="PASS"
if [[ $(dpkg-query -W -f='${Status}' "ansible" 2> /dev/null | grep -c "ok installed" || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Ansible Installed For Configuration Management" | tee -a "${TEST_FILE}"

# Verify extra package ripgrep was installed
((total_tests = total_tests + 1))
result="PASS"
if [[ $(dpkg-query -W -f='${Status}' "ripgrep" 2> /dev/null | grep -c "ok installed" || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Extra package 'ripgrep' installed" | tee -a "${TEST_FILE}"

# Results
echo "${TEST_CASE}: ${failed_tests} tests failed out of ${total_tests} total tests."
