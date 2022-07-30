# Notes

## Goals

I intend to automate Linux setups at two levels (three if user customizations, a.k.a. dotfiles, are counted).

### First Level

The first level are "provisioners".  These are files necessary to automate the paving of a machine from disk partitioning up to base installation of a terminal setup ready for further customization.  The bare minimum should be done but everything that is done should be done in a way that supports my later customizations even if it means slightly more complexity here.  I intend to support two kinds of provisioners.

- PreSeed, I use this term to broadly refer to the native installation automation provided by Debian and Ubuntu installers.  Newer versions of Ubuntu no longer use the old PreSeed logic and instead use Cloud Init but the concept is still the same.  (I also need to explore the cloud images of Debian.)  I intend to only support UEFI single-disk non-encrypted configurations here.  These automation environments are more limited and cumbersome.  As such, I want to keep things relatively basic and with less flexibility.  These really only serve as a backup or baseline method for comparison to the scripted versions.
- Scripted - This is the "Arch" way of installation but automated.  The script(s) should support UEFI systems only (no need for BIOS anymore).  Single disk unencrypted, single-disk encrypted, and dual-disk encrypted configurations should all be supported.

At present, it is my intent to support Debian and Ubuntu Linux distributions.  Longer term I may add Arch as well, and perhaps even retire Ubuntu.  I'm also considering Alpine, in order to mimic Docker like configurations inside VMs (lightweight and minimal).

### Second Level

The second level is system configuration and is to be entirely managed with Ansible scripts.  All environment combinations will include a "bare" configuration which skips this level and is a blank machine with only the first level scripts run.  Beyond that there will be multiple configurations and I would want the ability to test each automatically.  Some configurations will be more generic, like a basic server (a.k.a. "server") or a "desktop" (my common desktop configuration).  Others might be role specific ("docker server", "kubernetes node") or even down to the specific machine (specific configuration for "Aristotle" or "Marx", for instance).

At present, I have my "normal desktop" (currently KDE) and intend to have an alternate\experimental one as well.  I am strongly considering tiling WMs but may take another look at MATE, Cinnamon, XFCE, or even Gnome with Tiling extensions.  In all situations, my "main" desktop configuration will be referred to in configurations as "desktop" and the experimental one as "desktopAlt".  If the experimental becomes stable enough to use as my normal desktop, they will simply swap and the alternate one can then be used for other experiments.

**Ansible Idea:** I saw somewhere a guy used a single Ansible repo to then determine and load a separate Ansible repo that is specific to the machine.  So the logic of which Ansible repo to use for the specific machine\configuration is abstracted away.  May be a good way to organize things.

**Regarding Arch:** While I will have provisioning scripts for Arch, the system configurations for Arch will likely need to be entirely separate from Debian/Ubuntu as the systems are just so different.  At present, I have plans but no time frame to build the Ansible configs for Arch.

## Optional Third Level

These would be images that would also pull and configure my "home" directory with my dotfiles.  These would add "complete" to the configuration section of the file names such as "desktopComplete" or "serverComplete".

## Provisioners

I want to be able to automate the installation of Linux for single and dual disk configurations.  Single disk should support without encryption or with (the intent of the non-encrypted volumes is for virtual machines and disks, encryption balloons those disk images and they can not be compacted).  Dual only needs to support encryption as that is the only real context it will ever be used (physical machines).  There should be Packer scripts to test all three scenarios.  No "output" images or files should be created other than whatever is strictly needed for the tests to verify things thoroughly.  Given that these are only for testing VirtualBox will be the only thing targeted (longer term may want to convert this to KVM).

The configurations are:

- Debian
  - Stable
    - PreSeed (single-disk unencrypted only)
    - Scripted
      - Single Disk
      - Single Disk Encrypted
      - Dual Disk Encrypted
  - Testing
    - PreSeed (single-disk unencrypted only)
    - Scripted
      - Single Disk
      - Single Disk Encrypted
      - Dual Disk Encrypted
- Ubuntu
  - LTS
    - PreSeed (single-disk unencrypted only)
    - Scripted
      - Single Disk
      - Single Disk Encrypted
      - Dual Disk Encrypted
  - Rolling (Latest 6-month release, or the "rolling" branch?)
    - PreSeed (single-disk unencrypted only)
    - Scripted
      - Single Disk
      - Single Disk Encrypted
      - Dual Disk Encrypted

**Note:** These configurations differences are supported (and tested) by the packer scripts but do NOT produce output images as all of the virtualization images should always be single disk unencrypted.

## System Configurations

At present I want Ansible scripts for at least 4 "generic" configurations.

- Bare - These are essentially blank.  In essence, this is little different than just having the provisioner run.  If Ansible is used at all it should simply "verify/certify" the installation is consistent and therefore serve as the base scripts for all the others.  The only possible delta from the provisioner may be SSH configuration (chiefly key setup).
- Server - non-GUI but still fully configured with my setup/customizations for a terminal based server.  Suitable for running generic headless workloads.
- Desktop (Main one) - Full setup of my current desktop configuration (currently KDE).
- DesktopAlt (Experimental) - This will eventually become my standard desktop, and is used for testing and configuration of a different desktop environment.

## Testing Scripts

To fully test things, I want Packer scripts to fully automate and test the provisioners as well as the Ansible configurations (with possibly the exceptions of individual machine configurations - which is likely safe given they are based off the more generic configurations).  In every case, I want to use the single-disk unencrypted scripted setup as the focus of these tests is on the Ansible config not the provisioning script(s).  There should be only a single dual disk scripted bare setup just to verify the scripts ability to properly handle the dual disk scenario.

Also as with provisioners, no "output" should be created from these.  Furthermore, VirtualBox (later KVM) is all that needs to be targeted for testing purposes.

If tests are needed for "machine specific" configurations (such as "Aristotle") they will produce output but should be custom targeted to their environment, usually ProxMox.  This situation is likely to be used for manual testing and experimentation in a lab setting.  These scripts should be kept separate from the others for clarity.

## Image Creation

Finally, there should be Packer scripts to automate the creation of base images I intend to use in real virtualization settings.  The VM environments I wish to support are:

- VirtualBox (just an image, no vagrant)
- KVM Image
- Proxmox Image
- Vagrant VirtualBox Boxes
- Vagrant KVM Boxes
- AWS

Perhaps later:

- DigitalOcean
- Linode

Given that each of these is expected to be running in virtualized environments, it should be expected that the underlying machine/HyperVisor is already on a machine with encrypted disks.  As such, the only versions needed for output should be single-disk unencrypted hardware configurations.  However, for each I want to support the main "generic" system configurations (bare, server, desktopAlt, desktop).

**NOTE:** Depending on success of the other virtualization techs, I may retire VirtualBox entirely.  Both the main images as well as the Vagrant versions.

### Packer And Image Filenames

For both the packer files and the output artifacts I will use a naming pattern.

The full convention is as follows:

[test,local]-{{ virtualization platform }}-{{ distribution }}-{{ release or edition }}-{{ configuration }}

The output images will be prefixed with "bfee" for identification purposes.

#### Test & Local Files

The first section is optional and will only be used for the test files (most of which will not produce output).  Local is a special test case that uses local paths to the bootstrap scripts rather than their github location.  This makes doing development on the bootstrap scripts easier.

#### Virtualization Platform

This reflects the virtualization target for the image.  For the list of supported options see the "Image Creation" section above.

#### Distribution

The linux distribution.  Currently supporting Debian, Ubuntu with Arch to be added later.  No current plans to add others, but anything is possible.

For pre-seed versions the distribution section will include a pre-seed indicator, using camel casing (debianPreSeed, ubuntuPreSeed, etc.).  At some point I may retire the pre-seed scripts, but until then they will be separately indicated.

### Release or Edition

This is the branch name, release name, or edition name for the image.  Aliases such as "stable" or "testing" (Debian) or "lts" or "rolling" (Ubuntu) can be used.  Code names can also be used such as jammy, bookworm, and so on.  Finally, version numbers can be used such as 22.04 (Ubuntu) or 9 (Debian).  Whatever is preferred.  Arch, having no versions, will simply use "latest".

#### Configuration

This is based off the core configurations described in the "System Configurations" section above.  So: bare, server, desktop, desktopAlt

#### Outputs

The alternate desktop configuration is only needed for the Vagrant outputs (again for testing purposes).

This results in the following outputs:

**NOTE**: At present I am only setting up pre-seeds in vagrant Virtualbox for testing and verifications.  If I get rid of pre-seeds or get rid of using Virtualbox I may drop those entirely.

- vbox-debian-stable-server
- vbox-debian-stable-desktop
- vbox-debian-testing-server
- vbox-debian-testing-desktop
- vbox-ubuntu-lts-server
- vbox-ubuntu-lts-desktop
- vbox-ubuntu-rolling-server
- vbox-ubuntu-rolling-desktop
- kvm-debian-stable-server
- kvm-debian-stable-desktop
- kvm-debian-testing-server
- kvm-debian-testing-desktop
- kvm-ubuntu-lts-server
- kvm-ubuntu-lts-desktop
- kvm-ubuntu-rolling-server
- kvm-ubuntu-rolling-desktop
- proxmox-debian-stable-server
- proxmox-debian-stable-desktop
- proxmox-debian-testing-server
- proxmox-debian-testing-desktop
- proxmox-ubuntu-lts-server
- proxmox-ubuntu-lts-desktop
- proxmox-ubuntu-rolling-server
- proxmox-ubuntu-rolling-desktop
- vagrantVbox-debian-stable-bare
- vagrantVbox-debian-stable-barePreSeed
- vagrantVbox-debian-stable-server
- vagrantVbox-debian-stable-desktop
- vagrantVbox-debian-stable-desktopAlt
- vagrantVbox-debian-testing-bare
- vagrantVbox-debian-testing-barePreSeed
- vagrantVbox-debian-testing-server
- vagrantVbox-debian-testing-desktop
- vagrantVbox-debian-testing-desktopAlt
- vagrantVbox-ubuntu-lts-bare
- vagrantVbox-ubuntu-lts-barePreSeed
- vagrantVbox-ubuntu-lts-server
- vagrantVbox-ubuntu-lts-desktop
- vagrantVbox-ubuntu-lts-desktopAlt
- vagrantVbox-ubuntu-rolling-bare
- vagrantVbox-ubuntu-rolling-barePreSeed
- vagrantVbox-ubuntu-rolling-server
- vagrantVbox-ubuntu-rolling-desktop
- vagrantVbox-ubuntu-rolling-desktopAlt
- vagrantKvm-debian-stable-bare
- vagrantKvm-debian-stable-barePreSeed
- vagrantKvm-debian-stable-server
- vagrantKvm-debian-stable-desktop
- vagrantKvm-debian-stable-desktopAlt
- vagrantKvm-debian-testing-bare
- vagrantKvm-debian-testing-barePreSeed
- vagrantKvm-debian-testing-server
- vagrantKvm-debian-testing-desktop
- vagrantKvm-debian-testing-desktopAlt
- vagrantKvm-ubuntu-lts-bare
- vagrantKvm-ubuntu-lts-barePreSeed
- vagrantKvm-ubuntu-lts-server
- vagrantKvm-ubuntu-lts-desktop
- vagrantKvm-ubuntu-lts-desktopAlt
- vagrantKvm-ubuntu-rolling-bare
- vagrantKvm-ubuntu-rolling-barePreSeed
- vagrantKvm-ubuntu-rolling-server
- vagrantKvm-ubuntu-rolling-desktop
- vagrantKvm-ubuntu-rolling-desktopAlt

Cloud platforms only needs to support the server versions.  I may later add DigitalOcean and/or Linode.

- aws-debian-stable-server
- aws-debian-testing-server
- aws-ubuntu-lts-server
- aws-ubuntu-rolling-server

Later, I will add Arch versions:

- vbox-arch-latest-server
- vbox-arch-latest-desktop
- kvm-arch-latest-server
- kvm-arch-latest-desktop
- proxmox-arch-latest-server
- proxmox-arch-latest-desktop
- proxmox-arch-latest-server
- proxmox-arch-latest-desktop
- vagrantVbox-arch-latest-bare
- vagrantVbox-arch-latest-server
- vagrantVbox-arch-latest-desktop
- vagrantKvm-arch-latest-server
- vagrantKvm-arch-latest-desktop

## Docker

Use the base Debian and Ubuntu docker images to build up docker images to contain the tools and hardening I want.  Two general scenario's should be created:

- Test Containers, chiefly for testing Ansible.  Images are NOT meant for production use.
- Production Containers, base images that I would use to actually run/host things.

## Generate Encrypted Passwords

command:  echo 'test' | openssl passwd -6 -stdin

ubuntu: $6$Ky49b8mBZ1nrwHkn$DSQUXl/7h0UceoZtZYQD9moOLkNAlO2Z1UjUHhDvKDDH3PJdhWzGB3x9ox1Zjm742hECPz2sMXFZm.rtOIlR81

vagrant: $6$Z8XSoUNOS4kEe4Zw$aLjnDdun74QVneLokVLadzrzYBfFs2XV4cYAonWXfE6cur.ZBuFcVeyzCdzk586m6..oYKHndbwp5Fk5WaOZi1

test: $6$dBGHy9x3f7Ps8sqX$E4tLFh5LiGciwUoA4eLB1hMNTD84A2a3uejsm8jEsrVqob.pPgab1oRJdFFdPYYnSp7Qm0577PWKXooKCVDmM/

bob: $6$dhN9s4KsJOcAhUQe$gZWwUj9FJmgkFW8bVlYG3AWuQw784./lbsP4daftDupca7PC8qrC8iC/T9a6FXCKdftTGpehCCVU2tIE4mNN41

base64:

ubuntu: JDYkS3k0OWI4bUJaMW5yd0hrbiREU1FVWGwvN2gwVWNlb1p0WllRRDltb09Ma05BbE8yWjFValVIaER2S0RESDNQSmRoV3pHQjN4OW94MVpqbTc0MmhFQ1B6MnNNWEZabS5ydE9JbFI4MQo=

vagrant: JDYkWjhYU29VTk9TNGtFZTRadyRhTGpuRGR1bjc0UVZuZUxva1ZMYWR6cnpZQmZGczJYVjRjWUFvbldYZkU2Y3VyLlpCdUZjVmV5ekNkems1ODZtNi4ub1lLSG5kYndwNUZrNVdhT1ppMQo=

test: JDYkZEJHSHk5eDNmN1BzOHNxWCRFNHRMRmg1TGlHY2l3VW9BNGVMQjFoTU5URDg0QTJhM3VlanNtOGpFc3JWcW9iLnBQZ2FiMW9SSmRGRmRQWVluU3A3UW0wNTc3UFdLWG9vS0NWRG1NLwo=

bob: JDYkZGhOOXM0S3NKT2NBaFVRZSRnWld3VWo5RkptZ2tGVzhiVmxZRzNBV3VRdzc4NC4vbGJzUDRkYWZ0RHVwY2E3UEM4cXJDOGlDL1Q5YTZGWENLZGZ0VEdwZWhDQ1ZVMnRJRTRtTk40MQo=
