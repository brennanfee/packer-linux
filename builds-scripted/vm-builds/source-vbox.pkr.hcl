source "virtualbox-iso" "scripted" {
  format        = "ova"
  iso_interface = "sata"

  headless        = true

  communicator = "ssh"
  ssh_username = "${var.username}"
  ssh_password = "${var.password}"
  ssh_timeout  = "1h"
  ssh_handshake_attempts = 1000

  shutdown_command = "echo '${var.password}' | sudo -S systemctl poweroff"

  guest_additions_mode = "upload"

  # Machine configurations
  guest_os_type = "${var.os}_64"
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

  disk_additional_size = "${var.additional_disks}"

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
    ["setextradata", "{{.Name}}", "VBoxInternal2/EfiGraphicsResolution", "1280x720"],
  ]

  boot_wait = "3s"
  boot_command = [
    "e<wait3>",
    "<down><down><end> noeject noprompt<f10><wait30>",
    "sudo su <enter>",
    "/usr/bin/wget -O config.bash https://raw.githubusercontent.com/brennanfee/linux-bootstraps/${var.script_branch}/scripted-installer/debian/${local.config_script} <enter><wait5>",
    "export AUTO_IS_DEBUG=${var.is_debug} <enter>",
    "export AUTO_USERNAME=${var.username} <enter>",
    "export AUTO_USER_PWD=${var.password} <enter>",
    "/usr/bin/bash ./config.bash --auto-mode<enter>",
  ]
}
