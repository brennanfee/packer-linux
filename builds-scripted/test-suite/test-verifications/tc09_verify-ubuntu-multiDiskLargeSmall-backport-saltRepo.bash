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

# Verify the edition is jammy
((total_tests = total_tests + 1))
result="PASS"
temp=$(head -n 1 /etc/apt/sources.list | cut -d' ' -f 3 || true)
if [[ "${temp}" != "jammy" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: OS Edition" | tee -a "${TEST_FILE}"

# Verify the kernel is hwe-edge
release=$(lsb_release -r -s)
((total_tests = total_tests + 1))
result="PASS"
if [[ $(dpkg-query -W -f='${Status}' "linux-image-generic-hwe-${release}-edge" 2> /dev/null | grep -c "ok installed" || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: HWE Edge Kernel installed" | tee -a "${TEST_FILE}"

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

# Check three disk system
((total_tests = total_tests + 1))
result="PASS"
if [[ $(lsblk -nd -oNAME,RO | awk '/0$/ {print $1}' | grep -cv '^sr' || true) != "3" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Triple Disk System" | tee -a "${TEST_FILE}"

# Verify we did not encrypt the drives
((total_tests = total_tests + 1))
result="PASS"
if [[ $(wc -l /etc/crypttab | cut -d' ' -f 1 || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Not Encrypted" | tee -a "${TEST_FILE}"

# Validate root was installed on /dev/sdc (largest)
((total_tests = total_tests + 1))
result="PASS"
if [[ $(df --output=source / | tail -n1 || true) != /dev/sdc* ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: /dev/sdc was used for root installation" | tee -a "${TEST_FILE}"

# Validate home was installed on /dev/sda (smallest)
((total_tests = total_tests + 1))
result="PASS"
if [[ $(dmsetup deps -o devname vg_data-lv_home | sed -n -e 's/.*(\([^)]*\).*/\1/p' || true) != sda* ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: /dev/sda was used for /home installation" | tee -a "${TEST_FILE}"

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

# Validate the root password is "test"
((total_tests = total_tests + 1))
result="PASS"
attempt=$(echo 'test' | su -c "echo hello" root)
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

# Verify the salt repo key is in the keyring folder
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f "/usr/local/share/keyrings/salt-archive-keyring.gpg" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Salt Repository Key In Keyrings." | tee -a "${TEST_FILE}"

# Verify the apt file is in place
((total_tests = total_tests + 1))
result="PASS"
if [[ ! -f "/etc/apt/sources.list.d/salt.list" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Salt APT File exists." | tee -a "${TEST_FILE}"

# Verify that the salt-minion package was installed
((total_tests = total_tests + 1))
result="PASS"
if [[ $(dpkg-query -W -f='${Status}' "salt-minion" 2> /dev/null | grep -c "ok installed" || true) != "1" ]]; then
  ((failed_tests = failed_tests + 1))
  result="FAIL"
fi
echo "${result}: Salt package 'salt-minion' installed" | tee -a "${TEST_FILE}"

# Results
echo "${TEST_CASE}: ${failed_tests} tests failed out of ${total_tests} total tests."
