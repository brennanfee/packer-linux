#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=bios
## TEST_EDITION=backports
export AUTO_INSTALL_OS="debian"
export AUTO_INSTALL_EDITION="stable"
export AUTO_KERNEL_VERSION="backports"

export AUTO_MAIN_DISK="smallest"
export AUTO_SECOND_DISK="ignore"
export AUTO_ENCRYPT_DISKS=0

export AUTO_ROOT_PWD="thisIsRoot"
export AUTO_CREATE_USER=0
export AUTO_USERNAME=""
export AUTO_USER_PWD=""
export AUTO_USE_DATA_DIR=1

export AUTO_DOMAIN="mydomain.test"
