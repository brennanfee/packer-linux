#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=debian
## TEST_EDITION=sid
export AUTO_INSTALL_OS="debian"
export AUTO_INSTALL_EDITION="sid"
export AUTO_KERNEL_VERSION="default"

export AUTO_MAIN_DISK="/dev/sda"
export AUTO_SECOND_DISK="ignore"
export AUTO_ENCRYPT_DISKS=0

export AUTO_USERNAME="test"
export AUTO_USER_PWD="test"

export AUTO_REPO_OVERRIDE_URL="https://debian.osuosl.org/debian"

export AUTO_FIRST_BOOT_SCRIPT="https://raw.githubusercontent.com/brennanfee/packer-linux/main/test-scripts/test-first-boot-script.bash"
