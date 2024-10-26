variable "mandatory_tags" {}

variable "vpc_id" {
  type = string
}

variable "private_subnets_ids" {
  type    = list(string)
  default = [""]
}

variable "api_sg_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_admin_user" {
  type = string
}

variable "db_pwd" {
  type = string
}

variable "db_port" {
  type = number
}
