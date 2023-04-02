build {
  source "sources.virtualbox-iso.manual-scripted" {
    name             = "test-vbox-manual-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = "${var.preserve_image}"
    skip_export      = true
    vm_name          = "test-vbox-manual-bare"
    iso_url          = "https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.debian_iso_version}-live+nonfree/amd64/iso-hybrid/debian-live-${local.debian_iso_version}-amd64-standard+nonfree.iso"
    iso_checksum     = "file:https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.debian_iso_version}-live+nonfree/amd64/iso-hybrid/SHA256SUMS"

    firmware = "efi"

    boot_wait = "3s"
    boot_command = [
      "e<wait2>",
      "<down><down><end> noeject noprompt<f10><wait20>",
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
    ]
  }

  post-processor "manifest" {
    custom_data = {
      build_date = timestamp()
      image_name = "${build.ID}"
    }
  }
}
