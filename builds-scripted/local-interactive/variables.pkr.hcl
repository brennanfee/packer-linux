variable "os" {
  type    = string
  default = "debian"
}

variable "prefix" {
  type    = string
  default = "deb"
}

variable "additional_disks" {
  type    = list(number)
  default = []
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
}
