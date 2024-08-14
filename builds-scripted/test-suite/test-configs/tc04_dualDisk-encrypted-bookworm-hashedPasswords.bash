#!/usr/bin/env bash
# External script used to configure the test

## TEST_SOURCE_ISO=debian
## TEST_EDITION=bookworm
export AUTO_INSTALL_OS="debian"
export AUTO_INSTALL_EDITION="bookworm"
export AUTO_KERNEL_VERSION="default"

export AUTO_MAIN_DISK="smallest"
export AUTO_SECOND_DISK="smallest"
export AUTO_ENCRYPT_DISKS=1

export AUTO_DISK_PWD="https://raw.githubusercontent.com/brennanfee/packer-linux/main/test-scripts/test-encryption.key"

# shellcheck disable=SC2016
export AUTO_ROOT_PWD='$6$NYYggBY4vwD2ZtcU$G4E4CXzvk56E2z3PwSmWn0ecKuF29zpneG3OAUNuwMny7vHA4rg0dquye36CErAF07mnnBVykM880.UmUYuid1'
export AUTO_USERNAME="test"
# shellcheck disable=SC2016
export AUTO_USER_PWD='$6$ZIaxmfBK0x7WCw4l$ISLYiSs52XEIlGTnawnKQaWqrPaynB17pozOxfSlMX2AJU3QLcMwukdk7hW.oXyoFcrQ5DxyE1S7WcELiHNb81'

export AUTO_LOCALE="en_GB.UTF-8"

export AUTO_HOSTNAME="myhost"
export AUTO_DOMAIN="mydomain.test"

export AUTO_USE_DATA_DIR=0
export AUTO_STAMP_LOCATION="/xxx"

export AUTO_CONFIG_MANAGEMENT="puppet"
