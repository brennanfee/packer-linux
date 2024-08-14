#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=debian
## TEST_EDITION=jammy
export AUTO_INSTALL_OS="ubuntu"
export AUTO_INSTALL_EDITION="jammy"
export AUTO_KERNEL_VERSION="backports"

export AUTO_MAIN_DISK="largest"
export AUTO_SECOND_DISK="smallest"
export AUTO_ENCRYPT_DISKS=0

export AUTO_USERNAME="test"
export AUTO_USER_PWD="test"

export AUTO_CONFIG_MANAGEMENT="saltstack-repo"
