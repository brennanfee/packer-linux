build {
  source "sources.virtualbox-iso.scripted" {
    name             = "local-vbox-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = true
    skip_export      = true
    vm_name          = "local-vbox-${var.os}-${var.edition}-bare"
    iso_url          = "file:${path.root}/../../ISOs/debian/debian-live-amd64-standard.iso"
    iso_checksum     = "file:${path.root}/../../ISOs/debian/SHA256SUMS"

    firmware = "efi"

    boot_wait = "3s"
    boot_command = [
      "e<wait2>",
      "<down><down><end> noeject noprompt<f10><wait20>",
      "sudo su <enter>",
      "/usr/bin/wget -O config.bash http://{{ .HTTPIP }}:{{ .HTTPPort }}/deb-bootstrapper.bash <enter><wait5>",
      # Divert to the local copy of the installer for debugging purposes
      "export CONFIG_SCRIPT_SOURCE='${var.script_source}' <enter>",
      # Run the installer
      "/usr/bin/bash ./config.bash ${var.os} ${var.edition} ${var.config} --auto-mode ${var.flags}<enter>",
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
