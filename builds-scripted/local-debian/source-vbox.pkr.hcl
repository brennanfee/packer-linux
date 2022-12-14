source "virtualbox-iso" "debian-scripted" {
  format        = "ova"
  iso_interface = "sata"

  headless = false

  http_directory = "${path.root}/../../../linux-bootstraps/scripted-installer/debian/"

  communicator           = "ssh"
  ssh_username           = "${var.username}"
  ssh_password           = "${var.password}"
  ssh_timeout            = "1h"
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
    "e<wait2>",
    "<down><down><end> noeject noprompt<f10><wait20>",
    "sudo su <enter>",
    "/usr/bin/wget -O config.bash http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.config_script}<enter><wait5>",
    # Divert to the local copy of the installer for debugging purposes
    "export CONFIG_SCRIPT_SOURCE='http://{{ .HTTPIP }}:{{ .HTTPPort }}/deb-install.bash' <enter>",
    # Here to override what is in the config file
    "export AUTO_USERNAME=${var.username} <enter>",
    "export AUTO_USER_PWD=${var.password} <enter>",
    "export AUTO_ENCRYPT_DISKS=${var.auto_encrypt_disk} <enter>",
    # Tests
    #
    #"/usr/bin/wget -O config.bash http://{{ .HTTPIP }}:{{ .HTTPPort }}/deb-install-interactive.bash<enter><wait5>",
    # Run the installer
    "/usr/bin/bash ./config.bash -r<enter>",
  ]
}
