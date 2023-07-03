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

# Verify the edition is bookworm
((total_tests = total_tests + 1))
result="PASS"
temp=$(head -n 1 /etc/apt/sources.list | cut -d' ' -f 3 || true)
if [[ "${temp}" != "bookworm" ]]; then
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

# Domain is mydomain.test
((total_tests = total_tests + 1))
result="PASS"
if [[ $(hostname -d || true) != "mydomain.test" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Domain" | tee -a "${TEST_FILE}"

# Check current locale is en_GB.UTF-8
((total_tests = total_tests + 1))
result="PASS"
if [[ "${LC_ALL}" != "en_GB.UTF-8" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Locale Overriden" | tee -a "${TEST_FILE}"

# Check that en_US.UTF-8 is still available even if not current
((total_tests = total_tests + 1))
result="PASS"
if [[ $(locale -a | grep -c "en_US.utf8" || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Locale Overriden And 'US' still present" | tee -a "${TEST_FILE}"

# Timezone should be "American/Chicago"
((total_tests = total_tests + 1))
result="PASS"
if [[ $(cat /etc/timezone || true) != "America/Chicago" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Timezone Overriden" | tee -a "${TEST_FILE}"

# Check dual disk system
((total_tests = total_tests + 1))
result="PASS"
if [[ $(lsblk -nd -oNAME,RO | awk '/0$/ {print $1}' | grep -cv '^sr' || true) != "2" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Dual Disk Setup" | tee -a "${TEST_FILE}"

# Verify we did encrypt the drives
((total_tests = total_tests + 1))
result="PASS"
if [[ $(wc -l /etc/crypttab | cut -d' ' -f 1 || true) != "3" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Drives Encrypted" | tee -a "${TEST_FILE}"

# Verify root encryption key file
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f /boot/root.key ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Encryption key file" | tee -a "${TEST_FILE}"

# Validate the provided encryption file was used (by checking hash)
((total_tests = total_tests + 1))
result="PASS"
file_hash=$(shasum -a 256 /boot/root.key | cut -d' ' -f 1)
if [[ "${file_hash}" != "a595bccaf229712442ed4eb20c6ee4315a713e61b2b58cc701738c9f3c1dc9c9" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Provided encryption file was used" | tee -a "${TEST_FILE}"

# Verify the encryption key for the second disk
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f /etc/keys/secondary.key ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Secondary encryption file created and used" | tee -a "${TEST_FILE}"

# Validate root was installed on /dev/sda
((total_tests = total_tests + 1))
result="PASS"
if [[ $(df --output=source / | tail -n1 || true) != /dev/sda* ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: /dev/sda was used for root installation" | tee -a "${TEST_FILE}"

# Validate /home was installed on /dev/sdb
((total_tests = total_tests + 1))
result="PASS"
if [[ $(df --output=source /home | tail -n1 || true) != /dev/sdb* ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: /dev/sdb was used for /home installation" | tee -a "${TEST_FILE}"

# Validate we have a user "test"
((total_tests = total_tests + 1))
result="PASS"
if [[ $(getent passwd test || true) == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Test User Created" | tee -a "${TEST_FILE}"

# Check root account is not disabled
((total_tests = total_tests + 1))
result="PASS"
if [[ $(passwd -S root | cut -d' ' -f 2 || true) != "P" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Root enabled" | tee -a "${TEST_FILE}"

# Validate the user password is "test"
((total_tests = total_tests + 1))
result="PASS"
attempt=$(echo 'test' | su -c "echo hello" test)
if [[ "${attempt}" == "" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: User Password Verified" | tee -a "${TEST_FILE}"

# Validate the root password is "thisIsRoot"
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

# Make sure stamp location override was used despite data folder, /xxx
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f "/xxx/image_build_info" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Overridden Stamp Location Used" | tee -a "${TEST_FILE}"

# Verify that puppet was installed for config management
((total_tests = total_tests + 1))
result="PASS"
if [[ $(dpkg-query -W -f='${Status}' "puppet-agent" 2> /dev/null | grep -c "ok installed" || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Puppet Installed For Configuration Management" | tee -a "${TEST_FILE}"

# Results
echo "${TEST_CASE}: ${failed_tests} tests failed out of ${total_tests} total tests."
