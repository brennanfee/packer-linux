#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=debian
## TEST_EDITION=rolling
export AUTO_INSTALL_OS="ubuntu"
export AUTO_INSTALL_EDITION="rolling"
export AUTO_KERNEL_VERSION="default"

export AUTO_MAIN_DISK="/dev/sda"
export AUTO_SECOND_DISK="smallest"
export AUTO_ENCRYPT_DISKS=0

export AUTO_ROOT_PWD=""
export AUTO_USERNAME=""
export AUTO_USER_PWD=""

export AUTO_CONFIG_MANAGEMENT="ansible-pip"

export AUTO_EXTRA_PREREQ_PACKAGES="ripgrep"
export AUTO_BEFORE_SCRIPT="https://raw.githubusercontent.com/brennanfee/packer-linux/main/test-scripts/test-before-script-verify-preReqs.bash"
