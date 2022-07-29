packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "username" {
  type    = string
  default = "debian"
}

variable "password" {
  type    = string
  default = "debian"
}

locals {
  virtualization-type = "vbox"
  configuration = "dualBare"

  iso_version = "11.4.0"

  script_branch = "main"
  edition = "testing"
  config-script = "debian-my-configs/auto-${local.edition}-multiDisk.bash"
}

source "virtualbox-iso" "debian-scripted" {
  format        = "ova"
  iso_interface = "sata"

  headless        = false

  http_directory   = "${path.root}/../../linux-bootstraps/scripted-installer/debian/"
  output_directory = "${path.root}/output"

  communicator = "ssh"
  ssh_username = "${var.username}"
  ssh_password = "${var.password}"
  ssh_timeout  = "1h"
  ssh_handshake_attempts = 1000

  shutdown_command = "echo '${var.password}' | sudo -S systemctl poweroff"

  guest_additions_mode = "upload"

  # Machine configurations
  guest_os_type = "Debian_64"
  # Must use SATA as VirtualBox doesn't currently support export of NVME disks
  hard_drive_interface     = "sata"
  hard_drive_discard       = true
  hard_drive_nonrotational = true
  disk_size                = 81920
  firmware                 = "efi"
  memory                   = 4096
  cpus                     = 2
  usb                      = true
  gfx_controller           = "vmsvga"
  gfx_vram_size            = 128
  gfx_accelerate_3d        = true
  gfx_efi_resolution       = "1280x720"
  rtc_time_base            = "UTC"
  nested_virt              = true
  audio_controller         = "hda"
  sound                    = "pulse"

  disk_additional_size = [102400]

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--paravirtprovider", "default"],
    ["modifyvm", "{{.Name}}", "--pae", "on"],
    ["modifyvm", "{{.Name}}", "--acpi", "on"],
    ["modifyvm", "{{.Name}}", "--ioapic", "on"],
    ["modifyvm", "{{.Name}}", "--monitorcount", "1"],
    ["modifyvm", "{{.Name}}", "--hwvirtex", "on"],
    ["modifyvm", "{{.Name}}", "--nestedpaging", "on"],
    ["modifyvm", "{{.Name}}", "--clipboard-mode", "bidirectional"],
    ["modifyvm", "{{.Name}}", "--draganddrop", "bidirectional"],
    ["modifyvm", "{{.Name}}", "--mouse", "usbtablet"],
    ["modifyvm", "{{.Name}}", "--keyboard", "usb"],
    ["modifyvm", "{{.Name}}", "--audioout", "on"],
    ["modifyvm", "{{.Name}}", "--audioin", "on"],
    ["modifyvm", "{{.Name}}", "--usbehci", "off"],
    ["modifyvm", "{{.Name}}", "--usbxhci", "off"],
    ["modifyvm", "{{.Name}}", "--vrde", "off"],
    ["setextradata", "{{.Name}}", "GUI/SuppressMessages", "all"],
  ]

  boot_wait = "3s"
  boot_command = [
    "c<wait3>",
    "linux /live/vmlinuz-5.10.0-16-amd64 boot=live noeject noprompt components splash quiet --<enter>",
    "initrd /live/initrd.img-5.10.0-16-amd64<enter>",
    "boot<enter><wait30>",
    "sudo su <enter>",
    "/usr/bin/wget -O config.bash http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.config-script}<enter><wait5>",
#    "export AUTO_IS_DEBUG=0 <enter>",
    "export AUTO_REBOOT=1 <enter>",
    "export AUTO_USERNAME=debian <enter>",
#    "export AUTO_ENCRYPT_DISKS=0 <enter>",
    "/usr/bin/bash ./config.bash<enter>",
  ]
}

build {
  source "sources.virtualbox-iso.debian-scripted" {
    keep_registered = true
    skip_export     = true
    vm_name         = "bfee-debian-${local.edition}-${local.virtualization-type}-${local.configuration}"
    iso_url         = "https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.iso_version}-live+nonfree/amd64/iso-hybrid/debian-live-${local.iso_version}-amd64-standard+nonfree.iso"
    iso_checksum    = "file:https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.iso_version}-live+nonfree/amd64/iso-hybrid/SHA256SUMS"
  }

  #Should always be the last provisioner
  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
    scripts = [
      "${path.root}/../../linux-bootstraps/post-install-scripts/stamp.bash",
      "${path.root}/../../linux-bootstraps/post-install-scripts/minimize.bash",
    ]
  }

  # post-processor "manifest" {}

  # #  "rmdir ${path.root}/output-ubuntu/",
  # post-processor "shell-local" {
  #   inline = [
  #     "mv -f ${path.root}/output-ubuntu/*.ova ${path.root}/../images/",
  #     "mv -f ${path.root}/packer-manifest.json ${path.root}/../images/debian-vbox-manifest.json",
  #   ]
  # }
}
