build {
  source "sources.virtualbox-iso.manual-scripted" {
    name             = "test-vbox-manual-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = "${var.preserve_image}"
    skip_export      = true
    vm_name          = "test-vbox-manual-bare"
    iso_url          = "file:${path.root}/../../ISOs/debian/debian-live-amd64-standard.iso"
    iso_checksum     = "file:${path.root}/../../ISOs/debian/SHA256SUMS"

    firmware = "efi"

    boot_wait = "3s"
    boot_command = [
      "e<wait2>",
      "<down><down><end> noeject noprompt<f10><wait20>",
      "sudo su <enter>",
      "/usr/bin/wget -O config.bash https://raw.githubusercontent.com/brennanfee/linux-bootstraps/main/scripted-installer/debian/bootstraper.bash <enter><wait5>",
      "/usr/bin/bash ./config.bash ${var.os} ${var.edition} external http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.test_case_config_file} ${var.flags} --auto-mode<enter>",
    ]
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
    scripts = [
      "${path.root}/../../post-install-scripts/stamp.bash",
    ]
  }

  post-processor "manifest" {
    custom_data = {
      build_date = timestamp()
      image_name = "${build.ID}"
    }
  }
}
