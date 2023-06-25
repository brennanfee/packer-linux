variable "os" {
  type    = string
  default = "debian"
}

variable "edition" {
  type    = string
  default = "stable"
}

variable "username" {
  type    = string
  default = "debian"
}

variable "password" {
  type    = string
  default = "debian"
}

variable "script_branch" {
  type    = string
  default = "main"
}

variable "preserve_image" {
  type    = bool
  default = false
}

variable "is_debug" {
  type    = string
  default = "0"
}

variable "additional_disks" {
  type    = list(number)
  default = []
}

locals {
  iso_version = "12.0.0"

  config_script = "${var.os}-my-configs/${var.edition}-vm.bash"
}
