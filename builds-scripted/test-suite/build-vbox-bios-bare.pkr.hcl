build {
  source "sources.virtualbox-iso.bios-scripted" {
    name             = "test-vbox-bios-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = "${var.preserve_image}"
    skip_export      = true
    vm_name          = "test-vbox-bios-bare"
    iso_url          = "file:${path.root}/../../ISOs/debian/debian-live-amd64-standard.iso"
    iso_checksum     = "file:${path.root}/../../ISOs/debian/SHA256SUMS"

    firmware = "bios"

    boot_wait = "6s"
    boot_command = [
      "<tab><wait2>",
      " noeject noprompt<enter><wait20>",
      "sudo su <enter>",
      "/usr/bin/wget -O config.bash https://raw.githubusercontent.com/brennanfee/linux-bootstraps/main/scripted-installer/debian/bootstraper.bash <enter><wait5>",
      "/usr/bin/bash ./config.bash ${var.os} ${var.edition} external http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.test_case_config_file} ${var.flags} --auto-mode<enter>",
    ]
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
    scripts = [
      "${path.root}/../../post-install-scripts/stamp.bash",
      "${path.root}/test-verifications/${var.test_case_verification_script}",
    ]
  }

  provisioner "file" {
    source      = "/srv/test-results.txt"
    destination = "test-results.txt"
    direction   = "download"
  }

  post-processor "manifest" {
    custom_data = {
      build_date = timestamp()
      image_name = "${build.ID}"
    }
  }
}
