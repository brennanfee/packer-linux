# Local Debian Build Scripts

## Overview

This directory is used when I am making changes to the scripted installer script and need to test
local changes that have yet to be committed or merged to a branch. These require that both the
packer-linux (this repo) and the linux-bootstraps repo are checked out and sitting next to each
other.

## Running Builds

To run builds use the build.bash script provided in the directory (see its help for information on
usage).

## Configurations

This set of configurations provided here are to test the non-encrypted and encrypted versions of the
scripted installer with both single and multi-disk layouts. The test options provided here **DO
NOT** support testing anything other than a "bare" setup (which is to say that no Ansible or higher
configuration of the systems is supported). Given this is to test the scripted installer and any
changes in that script, those other configurations are omitted.

If testing those other configurations is necessary the os specific "test-{os}" folders are the
better option.
