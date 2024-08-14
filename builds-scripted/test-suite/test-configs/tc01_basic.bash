#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=debian
## TEST_EDITION=stable
export AUTO_INSTALL_OS="debian"
export AUTO_INSTALL_EDITION="stable"
export AUTO_KERNEL_VERSION="default"

export AUTO_MAIN_DISK="smallest"
export AUTO_SECOND_DISK="ignore"
export AUTO_ENCRYPT_DISKS="0"

export AUTO_CREATE_USER="1"
export AUTO_USERNAME="test"
export AUTO_USER_PWD="test"
