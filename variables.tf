variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "main_domain_name" {
  type = string
}

variable "static_website_domain" {
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

variable "fsa_api_docker_image_url" {
  type = string
}

variable "fsa_webapp_docker_image_url" {
  type = string
}