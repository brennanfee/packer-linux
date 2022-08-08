build {
  source "sources.virtualbox-iso.debian-scripted" {
    name             = "local-vagrantVbox-debian-bare"
    output_directory = "${path.root}/output-${source.name}"
    keep_registered  = true
    skip_export      = true
    vm_name          = "local-vagrantVbox-debian-${var.edition}-bare"
    iso_url          = "https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.iso_version}-live+nonfree/amd64/iso-hybrid/debian-live-${local.iso_version}-amd64-standard+nonfree.iso"
    iso_checksum     = "file:https://cdimage.debian.org/images/unofficial/non-free/images-including-firmware/${local.iso_version}-live+nonfree/amd64/iso-hybrid/SHA256SUMS"
  }

  // provisioner "file" {
  //   source = "${path.root}/../../post-install-scripts/vagrant.bash"
  //   destination = "/tmp/vagrant.bash"
  // }

  // provisioner "file" {
  //   source = "${path.root}/../../post-install-scripts/virtualbox.bash"
  //   destination = "/tmp/virtualbox.bash"
  // }

  // provisioner "shell" {
  //   execute_command = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
  //   inline = [
  //     "mv /tmp/*.bash /srv/"
  //   ]
  // }

  provisioner "shell" {
    execute_command   = "echo '${var.password}' | {{.Vars}} sudo -S -H -E bash -c '{{.Path}}'"
    expect_disconnect = true
    scripts = [
      "${path.root}/../../post-install-scripts/updates.bash",
      "${path.root}/../../post-install-scripts/vagrant.bash",
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

  // post-processor "vagrant" {
  //   output = "${path.root}/${build.ID}.box"
  // }
}
