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
