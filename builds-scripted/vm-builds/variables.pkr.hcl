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
  default = "svcacct"
}

variable "password" {
  type    = string
  default = "debian"
}

variable "vm_type" {
  type    = string
  default = "vm"
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
