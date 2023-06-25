variable "os" {
  type    = string
  default = "debian"
}

variable "edition" {
  type    = string
  default = "stable"
}

variable "script_config_type" {
  type    = string
  default = "vm"
}

variable "additional_disks" {
  type    = list(number)
  default = []
}

variable "auto_encrypt_disk" {
  type    = number
  default = 0
}

variable "username" {
  type    = string
  default = "debian"
}

variable "password" {
  type    = string
  default = "debian"
}

locals {
  iso_version = "12.0.0"

  config_script = "${var.os}-my-configs/${var.edition}-${var.script_config_type}.bash"
}
