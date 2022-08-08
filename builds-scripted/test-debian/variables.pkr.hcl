variable "username" {
  type    = string
  default = "debian"
}

variable "password" {
  type    = string
  default = "debian"
}

variable "edition" {
  type    = string
  default = "stable"
}

variable "script_branch" {
  type    = string
  default = "main"
}

variable "script_config_type" {
  type    = string
  default = "singleDisk"
}

variable "additional_disks" {
  type    = list(number)
  default = []
}

variable "preserve_image" {
  type    = bool
  default = false
}

variable "auto_encrypt_disk" {
  type    = number
  default = 0
}

variable "auto_reboot" {
  type    = number
  default = 1
}

locals {
  iso_version = "11.4.0"

  config_script = "debian-my-configs/auto-${var.edition}-${var.script_config_type}.bash"
}
