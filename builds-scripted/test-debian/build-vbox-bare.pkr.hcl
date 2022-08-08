build {
  source "sources.virtualbox-iso.debian-scripted" {
    name             = "test-vbox-debian-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = "${var.preserve_image}"
    skip_export      = false
    vm_name          = "test-vbox-debian-${var.edition}-bare"
    iso_url          = "https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.iso_version}-live+nonfree/amd64/iso-hybrid/debian-live-${local.iso_version}-amd64-standard+nonfree.iso"
    iso_checksum     = "file:https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.iso_version}-live+nonfree/amd64/iso-hybrid/SHA256SUMS"
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
