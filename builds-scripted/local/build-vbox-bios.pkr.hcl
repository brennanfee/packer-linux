build {
  source "sources.virtualbox-iso.scripted" {
    name             = "local-vbox-bios"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = true
    skip_export      = true
    vm_name          = "local-vbox-${var.os}-${var.edition}-bios"
    iso_url          = "file:${path.root}/../../ISOs/debian/debian-live-amd64-standard.iso"
    iso_checksum     = "file:${path.root}/../../ISOs/debian/SHA256SUMS"

    firmware = "bios"

    boot_wait = "6s"
    boot_command = [
      "<tab><wait2>",
      " noeject noprompt<enter><wait20>",
      "sudo su <enter>",
      "/usr/bin/wget -O config.bash http://{{ .HTTPIP }}:{{ .HTTPPort }}/packer-linux/builds-scripted/bootstrap-configs/${var.os}/vm-${var.edition}.bash <enter><wait5>",
      # Divert to the local copy of the installer for debugging purposes
      "export CONFIG_SCRIPT_SOURCE='http://{{ .HTTPIP }}:{{ .HTTPPort }}/linux-bootstraps/scripted-installer/debian/deb-install.bash' <enter>",
      # Here to override what is in the config file
      "export AUTO_IS_DEBUG=${var.is_debug} <enter>",
      "export AUTO_ENCRYPT_DISKS=${var.auto_encrypt_disk} <enter>",
      # Run the installer
      "/usr/bin/bash ./config.bash --auto-mode<enter>",
    ]
  }

  provisioner "shell" {
    execute_command   = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
    expect_disconnect = true
    scripts = [
      "${path.root}/../../post-install-scripts/updates.bash",
      "${path.root}/../../post-install-scripts/virtualbox.bash",
      "${path.root}/../../post-install-scripts/reboot.bash",
    ]
  }

  # Should always be the last provisioner
  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
    scripts = [
      "${path.root}/../../post-install-scripts/stamp.bash",
      "${path.root}/../../post-install-scripts/minimize.bash",
    ]
  }

  post-processor "manifest" {
    custom_data = {
      build_date = timestamp()
      image_name = "${build.ID}"
    }
  }
}
