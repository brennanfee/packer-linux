# Test Image Builders For The Debian Scripted Installer

## Overview

These scripts allow testing of a host of different configurations of machines using my debian scripted installer as well as my Ansible setups for various machine types.

## Configurations

While this directory is intended to test as many different configuration combinations supported by the Scripted Installer and by my Ansible scripts, I only limitedly test some of the Scripted Installer configurations (as in having only 1 test) such as multi-disk configurations and disk encryption.  They are tested just to verify they work but I don't provide multiple combinations of that along with other machine types because the permutations would grow out of control.  Furthermore, it is assumed that if any multi-disk instance could be created that it would work in all other combinations, same with encryption.

The other permutations provided have to do with the Ansible setup of the given instance.

## Virtualization Types

As with multi-disk and encryption, we don't need to test each virtualization type for every combination.  Therefore, there will frequently be only one test for a particular configuration type merely to verify that the automation scripts for creating that type of image do in fact work.

At present the following virtualization types are supported\tested:

- Virtualbox
- Vagrant on top of Virtualbox

Others may be added later.

## How The Images Are Tested And Verified

Generally, the default for these scripts is to create the image, if selected to run a particular Ansible configuration, then optionally run some shell scripts for testing\verification of the image, and finally to **DESTROY** the image.  These scripts are not intended to create permanent versions of the specific configured images but merely test that they are "working" and "correct".

However, when actively working on changes to either the Scripted Installer or Ansible configurations it can at times be helpful to preserve the image to be booted and explored\verified manually.  To support that scenario, the build script supports a '--keep' option that will keep the image rather than destroy it.  **NOTE:** After keeping an image, ANY run of the build script will destroy the image first before continuing.
