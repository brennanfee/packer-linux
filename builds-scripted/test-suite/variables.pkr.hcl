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

variable "flags" {
  type    = string
  default = ""
}

variable "test_case_config_file" {
  type = string
}

variable "test_case_verification_script" {
  type    = string
  default = "noop.bash"
}
