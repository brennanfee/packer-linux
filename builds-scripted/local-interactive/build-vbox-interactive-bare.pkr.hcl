build {
  source "sources.virtualbox-iso.scripted" {
    name             = "local-vbox-interactive-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = true
    skip_export      = true
    vm_name          = "local-vbox-interactive-bare"
    iso_url          = "https://cdimage.debian.org/images/release/${local.iso_version}-live/amd64/iso-hybrid/debian-live-${local.iso_version}-amd64-standard.iso"
    iso_checksum     = "file:https://cdimage.debian.org/images/release/${local.iso_version}-live/amd64/iso-hybrid/SHA256SUMS"
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
