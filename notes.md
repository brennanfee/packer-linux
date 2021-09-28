# Notes

## Goals

I intend to automate Linux setups at two levels (three if user customizations, a.k.a. dotfiles, are counted).

### First Level

The first level are "provisioners".  These are files necessary to automate the paving of a machine from disk partitioning up to base installation of a terminal setup ready for further customization.  The bare minimum should be done but everything that is done should be done in a way that supports my later customizations even if it means slightly more complexity here.  I intend to support two kinds of provisioners.

- PreSeed, I use this term to broadly refer to the native installation automation provided by Debian and Ubuntu installers.  Newer versions of Ubuntu no longer use the PreSeed logic but the concept is still the same.  I intend to only support UEFI single-disk non-encrypted configurations here.  These automation environments and are more limited and cumbersome.  As such, I want to keep things relatively basic.  These really only serve as a backup or baseline method for comparison to the scripted versions.
- Scripted - This is the "Arch" way of installation but automated.  The script(s) should support UEFI systems only (no need for BIOS).  Single disk unencrypted, single-disk encrypted, and dual-disk encrypted configurations should all be supported.

At present, I it is my intent to support three Linux distributions:

- Debian
- Ubuntu
- Arch
- Alpine (?)

### Second Level

The second level is system configuration and is to be entirely managed with Ansible scripts and configurations.  There will be multiple configurations and I would want the ability to test each automatically.  Some configurations will be more generic, like a basic server (a.k.a. "server") or a "desktop" (my common desktop configuration).  Others might be role specific ("docker server", "kubernetes node") or even down to the specific machine (specific configuration for "Aristotle" or "Marx", for instance).

At present, for desktops I use KDE.  For now, the desktop configurations will reflect that.  However, I do intent to experiment and will create a secondary set of desktop configurations to test other things out until I find one I like and it becomes more stable and reliable.  Strongly considering tiling WMs but may take another look at MATE, Cinnamon, XFCE, or even Gnome with Tiling.

**Regarding Arch:** While I will have provisioning scripts for Arch, the system configurations for Arch will likely need to be entirely separate from Debian/Ubuntu as the systems are just so different.  At present, I have plans but no timeframe to build the Ansible configs for Arch.

## Provisioners

I want to be able to automate the installation of Linux for single and dual disk configurations.  Single disk should support without encryption or with.  Dual only needs to support encryption as that is the only real context it will ever be used.  There should be Packer scripts to test all three scenarios.  No "output" images or fils should be created other than whatever is strictly needed for the tests to verify things thoroughly.  Given that these are only for testing VirtualBox will be the only thing targeted (longer term may want to convert this to KVM).

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
  - Rolling
    - PreSeed (single-disk unencrypted only)
    - Scripted
      - Single Disk
      - Single Disk Encrypted
      - Dual Disk Encrypted

## System configuration(s)

At present I want Ansible scripts for at least 4 "generic" configurations.

- Bare - These are essentially blank.  In essence, this is little different than just having the provisioner run.  If Ansible is used at all it should simply "verify/certify" the installation is consistent and therefore serve as the base scripts for all the others.  The only possible delta from the provisioner may be SSH configuration (chiefly key setup).
- Server - non-GUI but still fully configured with my setup/customizations for a terminal based server.  Suitable for running headless workloads.
- Desktop (KDE) - Full GUI setup with KDE and all my usual desired things.
- Desktop (TBD) - This will eventually become my standard desktop, ideally a tiling WM.

As with the provisioners, I want Packer scripts to fully automate and test these.  In every case, I want to use the single-disk unencrypted scripted setup as the focus of these tests is on the Ansible config not the provisioning script(s).

Also as with provisioners, no "output" should be created from these.  Furthermore, VirtualBox (later KVM) is all that needs to be targeted for testing purposes.

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

Given that each of these is expected to be running in virtualized environments, it should be expected that the underlying machine/HyperVisor is already on a machine with encrypted disks.  As such, the only versions needed for output should be single-disk unencrypted hardware configurations.  However, for each I want to support the 2 main "generic" system configurations (server, desktop).  Only the main vagrant virtualization (currently VirtualBox, later KVM) should support the other two (bare, desktop-alternate).

**NOTE:** Depending on success of the other virtualization techs, I may retire VirtualBox entirely.  Both the main images as well as the Vagrant versions.

Image naming pattern:

{{ virtualization platform }}-{{ distribution }}-{{ edition }}-{{ configuration }}

Arch will simply use "latest" for edition.

This results in the following outputs:

**NOTE: TBD** Considering a change, pre-seed single-disk only in kvm & vagrant kvm only in both Server & Desktop variations.  For the script all the various combinations would be provided, single & dual-disk, encrypted & non-encrypted, all platforms with vagrant for virtualbox & kvm.

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
- vagrantKvm-debian-stable-server
- vagrantKvm-debian-stable-desktop
- vagrantKvm-debian-testing-server
- vagrantKvm-debian-testing-desktop
- vagrantKvm-ubuntu-lts-server
- vagrantKvm-ubuntu-lts-desktop
- vagrantKvm-ubuntu-rolling-server
- vagrantKvm-ubuntu-rolling-desktop

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
- vagrantVbox-arch-latest-server
- vagrantVbox-arch-latest-desktop
- vagrantKvm-arch-latest-server
- vagrantKvm-arch-latest-desktop

## Docker

Use the base Debian and Ubuntu docker images to build up docker images to contain the tools and hardening I want.  Two general scenario's should be created:

- Test Containers, chiefly for testing Ansible.  Images are NOT meant for production use.
- Production Containers, base images that I would use to actually run/host things.

## Crypted Passwords

command:  echo 'test' | mkpasswd -s -m sha512crypt
also: echo 'test' | openssl passwd -6 -stdin

ubuntu: $6$Ky49b8mBZ1nrwHkn$DSQUXl/7h0UceoZtZYQD9moOLkNAlO2Z1UjUHhDvKDDH3PJdhWzGB3x9ox1Zjm742hECPz2sMXFZm.rtOIlR81

vagrant: $6$Z8XSoUNOS4kEe4Zw$aLjnDdun74QVneLokVLadzrzYBfFs2XV4cYAonWXfE6cur.ZBuFcVeyzCdzk586m6..oYKHndbwp5Fk5WaOZi1

test: $6$dBGHy9x3f7Ps8sqX$E4tLFh5LiGciwUoA4eLB1hMNTD84A2a3uejsm8jEsrVqob.pPgab1oRJdFFdPYYnSp7Qm0577PWKXooKCVDmM/

bob: $6$dhN9s4KsJOcAhUQe$gZWwUj9FJmgkFW8bVlYG3AWuQw784./lbsP4daftDupca7PC8qrC8iC/T9a6FXCKdftTGpehCCVU2tIE4mNN41

base64:

ubuntu: JDYkS3k0OWI4bUJaMW5yd0hrbiREU1FVWGwvN2gwVWNlb1p0WllRRDltb09Ma05BbE8yWjFValVIaER2S0RESDNQSmRoV3pHQjN4OW94MVpqbTc0MmhFQ1B6MnNNWEZabS5ydE9JbFI4MQo=

vagrant: JDYkWjhYU29VTk9TNGtFZTRadyRhTGpuRGR1bjc0UVZuZUxva1ZMYWR6cnpZQmZGczJYVjRjWUFvbldYZkU2Y3VyLlpCdUZjVmV5ekNkems1ODZtNi4ub1lLSG5kYndwNUZrNVdhT1ppMQo=

test: JDYkZEJHSHk5eDNmN1BzOHNxWCRFNHRMRmg1TGlHY2l3VW9BNGVMQjFoTU5URDg0QTJhM3VlanNtOGpFc3JWcW9iLnBQZ2FiMW9SSmRGRmRQWVluU3A3UW0wNTc3UFdLWG9vS0NWRG1NLwo=

bob: JDYkZGhOOXM0S3NKT2NBaFVRZSRnWld3VWo5RkptZ2tGVzhiVmxZRzNBV3VRdzc4NC4vbGJzUDRkYWZ0RHVwY2E3UEM4cXJDOGlDL1Q5YTZGWENLZGZ0VEdwZWhDQ1ZVMnRJRTRtTk40MQo=
