variable "username" {
  type    = string
  default = "test"
}

variable "password" {
  type    = string
  default = "test"
}

variable "additional_disks" {
  type    = list(number)
  default = []
}

variable "preserve_image" {
  type    = bool
  default = false
}

variable "is_debug" {
  type    = string
  default = "0"
}

variable "test_case_config_file" {
  type = string
}

variable "test_case_verification_script" {
  type    = string
  default = "noop.bash"
}

locals {
  debian_iso_version = "12.0.0"
  ubuntu_iso_version = "22.04.2"
}
