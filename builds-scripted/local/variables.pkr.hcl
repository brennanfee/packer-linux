variable "os" {
  type    = string
  default = "debian"
}

variable "edition" {
  type    = string
  default = "stable"
}

variable "additional_disks" {
  type    = list(number)
  default = []
}

variable "auto_encrypt_disk" {
  type    = number
  default = 0
}

variable "is_debug" {
  type    = string
  default = "0"
}

variable "username" {
  type    = string
  default = "root"
}

variable "password" {
  type    = string
  default = "debian"
}
