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

variable "fsa_api_base_url" {
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

variable "health_check_path" {
  type = string
}

variable "main_domain_name" {
  type = string
}

variable "static_website_domain" {
  type = string
}

