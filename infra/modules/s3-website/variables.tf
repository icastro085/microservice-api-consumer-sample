variable "bucket" {
  type = string
}

variable "is_website" {
  type    = bool
  default = false
}

variable "is_public_read" {
  type    = bool
  default = false
}
