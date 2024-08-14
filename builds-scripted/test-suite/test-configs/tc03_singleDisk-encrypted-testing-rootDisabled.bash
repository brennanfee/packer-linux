#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=debian
## TEST_EDITION=testing
export AUTO_INSTALL_OS="debian"
export AUTO_INSTALL_EDITION="testing"
export AUTO_KERNEL_VERSION="default"

export AUTO_MAIN_DISK="smallest"
export AUTO_SECOND_DISK="largest"
export AUTO_ENCRYPT_DISKS=1

export AUTO_ROOT_DISABLED=1
export AUTO_CREATE_USER="1"
export AUTO_USERNAME="test"
export AUTO_USER_PWD="test"

export AUTO_TIMEZONE="America/Los_Angeles"
export AUTO_HOSTNAME="myhost"

export AUTO_USE_DATA_DIR=1
export AUTO_STAMP_LOCATION="/xxx"

export AUTO_CONFIG_MANAGEMENT="ansible"
export AUTO_EXTRA_PACKAGES="ripgrep"
