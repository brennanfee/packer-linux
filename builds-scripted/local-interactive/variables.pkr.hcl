variable "platform" {
  type    = string
  default = "debian"
}

variable "platform_prefix" {
  type    = string
  default = "deb"
}

variable "additional_disks" {
  type    = list(number)
  default = []
}

variable "is_debug" {
  type    = string
  default = "0"
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
  debian_iso_version = "12.0.0"
  arch_iso_version   = "2023.07.01"
}
