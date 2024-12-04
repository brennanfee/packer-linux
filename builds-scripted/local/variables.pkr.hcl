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

variable "additional_disks" {
  type    = list(number)
  default = []
}

variable "config" {
  type    = string
  default = "default"
}

variable "flags" {
  type    = string
  default = ""
}

variable "script_source" {
  type    = string
  default = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/deb-install.bash"
}
