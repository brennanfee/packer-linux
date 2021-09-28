packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "hostname" {
  type    = string
  default = "vagrant"
}

variable "username" {
  type    = string
  default = "vagrant"
}

variable "password" {
  type    = string
  default = "vagrant"
}

locals {
  version = "21.04"
  edition = "rolling"
}

source "virtualbox-iso" "ubuntu-preseed" {
  format        = "ova"
  iso_interface = "sata"

  headless = false

  http_directory   = "${path.root}/http"
  output_directory = "${path.root}/output"

  communicator           = "ssh"
  ssh_username           = "${var.username}"
  ssh_password           = "${var.password}"
  ssh_timeout            = "1h"
  ssh_handshake_attempts = 1000

  shutdown_command = "echo '${var.password}' | sudo -S systemctl poweroff"

  guest_additions_mode = "upload"

  # Machine configurations
  guest_os_type = "Ubuntu_64"
  # Must use SATA as VirtualBox doesn't currently support export of NVME disks
  hard_drive_interface     = "sata"
  hard_drive_discard       = true
  hard_drive_nonrotational = true
  disk_size                = 102400
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

  # disk_additional_size = [102400]

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
    "c<wait3> ",
    "linux /casper/vmlinuz ",
    "\"ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ubuntu/\" ",
    "AUTO_HOSTNAME=${var.hostname} ",
    "AUTO_USERNAME=${var.username} ",
    "AUTO_PASSWORD=${var.password} ",
    "quiet autoinstall ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
}

build {
  source "sources.virtualbox-iso.ubuntu-preseed" {
    keep_registered = false
    skip_export     = false
    vm_name         = "bfee-ubuntu-${local.edition}-vagrantVbox-barePreseed"
    iso_url         = "https://releases.ubuntu.com/${local.version}/ubuntu-${local.version}-live-server-amd64.iso"
    iso_checksum    = "file:https://releases.ubuntu.com/${local.version}/SHA256SUMS"
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
    scripts = [
      "${path.root}/../scripts/setupDataDir.bash",
      "${path.root}/../scripts/basePackages.bash",
      "${path.root}/../scripts/setupSvcUser.bash",
      "${path.root}/../scripts/updates.bash",
      "${path.root}/../scripts/ubuntu-hwe.bash",
      "${path.root}/../scripts/reboot.sh",
      "${path.root}/../scripts/ansible.bash",
      "${path.root}/../scripts/virtualbox.bash",
      "${path.root}/../scripts/reboot.sh",
      "${path.root}/../scripts/vagrant.bash",
      "${path.root}/../scripts/setupGroups.bash",
      "${path.root}/../scripts/stamp.bash",
      "${path.root}/../scripts/minimize.bash"
    ]
    expect_disconnect = true
  }

  post-processor "manifest" {}

  post-processor "vagrant" {
    output = "${path.root}/../images/bfee-ubuntu-${local.edition}-vagrantVbox-barePreseed.box"
  }

  post-processor "shell-local" {
    inline = [
      "mv -f ${path.root}/packer-manifest.json ${path.root}/../images/bfee-ubuntu-${local.edition}-vagrantVbox-barePreseed-manifest.json",
    ]
  }
}
