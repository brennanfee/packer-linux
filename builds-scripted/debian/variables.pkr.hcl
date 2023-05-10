variable "username" {
  type    = string
  default = "debian"
}

variable "password" {
  type      = string
  default   = "debian"
}

variable "edition" {
  type    = string
  default = "stable"
}

variable "script_branch" {
  type = string
  default = "main"
}

variable "is_debug" {
  type = string
  default = "0"
}

locals {
  iso_version = "11.7.0"

  config_script = "debian-my-configs/${var.edition}-vm.bash"
}
