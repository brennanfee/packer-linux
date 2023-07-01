build {
  source "sources.virtualbox-iso.scripted" {
    name             = "local-vbox-interactive-arch"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = true
    skip_export      = true
    vm_name          = "local-vbox-interactive-arch"
    iso_url          = "https://mirror.rackspace.com/archlinux/iso/${local.arch_iso_version}/archlinux-${local.arch_iso_version}-x86_64.iso"
    iso_checksum     = "file:https://mirror.rackspace.com/archlinux/iso/${local.arch_iso_version}/sha256sums.txt"
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
