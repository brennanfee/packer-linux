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

# Verify the target OS is ubuntu
((total_tests = total_tests + 1))
result="PASS"
temp=$(lsb_release -i -s | tr "[:upper:]" "[:lower:]" || true)
if [[ "${temp}" != "ubuntu" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Target OS" | tee -a "${TEST_FILE}"

# Verify the edition is lunar
((total_tests = total_tests + 1))
result="PASS"
temp=$(head -n 1 /etc/apt/sources.list | cut -d' ' -f 3 || true)
if [[ "${temp}" != "lunar" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: OS Edition" | tee -a "${TEST_FILE}"

# Hostname was auto-generated
((total_tests = total_tests + 1))
result="PASS"
if [[ $(hostname -s | grep -P '^ubuntu-\d{1,5}$' || true) == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Hostname" | tee -a "${TEST_FILE}"

# No domain was used
((total_tests = total_tests + 1))
result="PASS"
if [[ $(hostname -s || true) != $(hostname -f || true) ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Domain" | tee -a "${TEST_FILE}"

# Check current locale is en_US.UTF-8
((total_tests = total_tests + 1))
result="PASS"
if [[ "${LC_ALL}" != "en_US.UTF-8" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Locale Correct" | tee -a "${TEST_FILE}"

# Timezone should be "American/Chicago"
((total_tests = total_tests + 1))
result="PASS"
if [[ $(cat /etc/timezone || true) != "America/Chicago" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Timezone Correct" | tee -a "${TEST_FILE}"

# Check single disk system
((total_tests = total_tests + 1))
result="PASS"
if [[ $(lsblk -nd -oNAME,RO | awk '/0$/ {print $1}' | grep -cv '^sr' || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Single Disk Setup" | tee -a "${TEST_FILE}"

# Verify we did not encrypt the drive
((total_tests = total_tests + 1))
result="PASS"
if [[ $(wc -l /etc/crypttab | cut -d' ' -f 1 || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Not Encrypted" | tee -a "${TEST_FILE}"

# Validate we have a user "ubuntu"
((total_tests = total_tests + 1))
result="PASS"
if [[ $(getent passwd ubuntu || true) == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Ubuntu User Created" | tee -a "${TEST_FILE}"

# Check root account is not disabled
((total_tests = total_tests + 1))
result="PASS"
if [[ $(passwd -S root | cut -d' ' -f 2 || true) != "P" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Root enabled" | tee -a "${TEST_FILE}"

# Validate the user password is "ubuntu"
((total_tests = total_tests + 1))
result="PASS"
attempt=$(echo 'ubuntu' | su -c "echo hello" ubuntu)
if [[ "${attempt}" == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: User Password Verified" | tee -a "${TEST_FILE}"

# Validate the root password is "ubuntu"
((total_tests = total_tests + 1))
result="PASS"
attempt=$(echo 'thisIsRoot' | su -c "echo hello" root)
if [[ "${attempt}" == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
unset attempt
echo "${result}: Root Password Verified" | tee -a "${TEST_FILE}"

# Data folder should NOT exist
((total_tests = total_tests + 1))
result="PASS"
if [[ -d "/data" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Data Folder Should NOT exist" | tee -a "${TEST_FILE}"

# Make sure default stamp location was used /srv
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f "/srv/image_build_info" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Default Stamp Location Used" | tee -a "${TEST_FILE}"

# Verify that ansible was installed (from pip) for config management
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -x /root/.local/bin/ansible ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Ansible (PIP) Installed For Configuration Management" | tee -a "${TEST_FILE}"

# Verify the before script was run
((total_tests = total_tests + 1))
result="PASS"
if [[ $(grep -c "BEFORE SCRIPT:" /srv/install-log.log || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Before Script was executed." | tee -a "${TEST_FILE}"

# Results
echo "${TEST_CASE}: ${failed_tests} tests failed out of ${total_tests} total tests."
