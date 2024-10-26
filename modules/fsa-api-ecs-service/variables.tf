variable "mandatory_tags" {}

variable "name" {
  type = string
}

variable "app_port" {
  type = number
}

variable "ecs_cluster_id" {
  type = string
}

variable "docker_image_url" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_admin_user" {
  type = string
}

variable "db_pwd" {
  type = string
}

variable "db_name" {
  type = string
}

variable "answer_endpoint" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "private_subnets_ids" {
  type    = list(string)
  default = [""]
}

variable "public_subnets_ids" {
  type    = list(string)
  default = [""]
}

variable "web_app_sg_id" {
  type = string
}