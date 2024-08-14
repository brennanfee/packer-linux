#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=debian
## TEST_EDITION=ltsedge
export AUTO_INSTALL_OS="ubuntu"
export AUTO_INSTALL_EDITION="lts"
export AUTO_KERNEL_VERSION="hwe-edge"

export AUTO_MAIN_DISK="smallest"
export AUTO_SECOND_DISK="smallest"
export AUTO_ENCRYPT_DISKS=1
export AUTO_DISK_PWD="/home/user/test-encryption.key"

export AUTO_USERNAME="test"
export AUTO_USER_PWD="test"

export AUTO_CONFIG_MANAGEMENT="puppet-repo"

export AUTO_BEFORE_SCRIPT="https://raw.githubusercontent.com/brennanfee/packer-linux/main/test-scripts/test-before-download-preReqs.bash"
export AUTO_AFTER_SCRIPT="/home/user/test-after-script.py"
