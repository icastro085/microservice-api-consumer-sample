variable "env" {
  type = string

  # validation {
  #   condition     = contains(["development", "staging", "production"], var.env)
  #   error_message = "variable env  needs to be: development | staging | production"
  # }
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "aws_s3_use_path_style" {
  type    = bool
  default = false
}

variable "aws_skip_credentials_validation" {
  type    = bool
  default = false
}

variable "aws_skip_metadata_api_check" {
  type    = bool
  default = false
}

variable "aws_skip_requesting_account_id" {
  type    = bool
  default = false
}
