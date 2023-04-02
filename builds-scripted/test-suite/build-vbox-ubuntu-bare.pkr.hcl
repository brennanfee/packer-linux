build {
  source "sources.virtualbox-iso.ubuntu-scripted" {
    name             = "test-vbox-ubuntu-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = "${var.preserve_image}"
    skip_export      = true
    vm_name          = "test-vbox-ubuntu-bare"
    iso_url          = "https://releases.ubuntu.com/${local.ubuntu_iso_version}/ubuntu-${local.ubuntu_iso_version}-live-server-amd64.iso"
    iso_checksum     = "file:https://releases.ubuntu.com/${local.ubuntu_iso_version}/SHA256SUMS"

    firmware = "efi"

    boot_wait = "3s"
    boot_command = [
      "<enter><wait60>",
      "<f2><wait2>",
      "sudo su <enter>",
      "/usr/bin/wget -O config.bash http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.test_case_config_file} <enter><wait5>",
      "export AUTO_IS_DEBUG=${var.is_debug} <enter>",
      "/usr/bin/bash ./config.bash --auto-mode<enter>",
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
    source = "/srv/test-results.txt"
    destination = "test-results.txt"
    direction = "download"
  }

  post-processor "manifest" {
    custom_data = {
      build_date = timestamp()
      image_name = "${build.ID}"
    }
  }
}
