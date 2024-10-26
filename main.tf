module "tags" {
  source          = "./modules/tags"
  application     = "flights-stackoverflow-answers"
  project         = "learn-aws-2"
  team            = "infrastructure"
  environment     = "dev"
  owner           = "giraffeman123"
  project_version = "1.0"
  contact         = "giraffeman123@gmail.com"
  cost_center     = "35009"
  sensitive       = false
}

# module "imported-vpc" {
#   source = "./modules/imported-vpc"
#   vpc_id = var.vpc_id
# }

module "vpc" {
  source                     = "./modules/new-vpc"
  mandatory_tags             = module.tags.mandatory_tags
  vpc_cidr_block             = "10.0.0.0/16"
  public_subnets_cidr_block  = ["10.0.0.0/20", "10.0.128.0/20"]
  private_subnets_cidr_block = ["10.0.16.0/20", "10.0.144.0/20"]
}

module "rds" {
  source              = "./modules/rds"
  mandatory_tags      = module.tags.mandatory_tags
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
  db_name             = var.db_name
  db_admin_user       = var.db_admin_user
  db_pwd              = var.db_pwd
  db_port             = 3306
  api_sg_id           = module.fsa_api_ecs_service.ecs_service_sg
}

module "ecs_cluster" {
  source         = "./modules/ecs-cluster"
  mandatory_tags = module.tags.mandatory_tags
  cluster_name           = "flights-and-answers"
}

module "fsa_api_ecs_service" {
  source              = "./modules/fsa-api-ecs-service"
  mandatory_tags      = module.tags.mandatory_tags
  name                = "fsa-api"
  app_port            = 3000
  ecs_cluster_id      = module.ecs_cluster.cluster_id
  docker_image_url    = var.fsa_api_docker_image_url
  db_host             = module.rds.db_host
  db_name             = var.db_name
  db_admin_user       = var.db_admin_user
  db_pwd              = var.db_pwd
  answer_endpoint     = "https://api.stackexchange.com/2.2/search?order=desc&sort=activity&intitle=perl&site=stackoverflow"
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
  public_subnets_ids  = module.vpc.public_subnets_ids
  health_check_path   = "/liveness"
  web_app_sg_id       = module.webapp_ecs_service.ecs_service_sg
}

module "webapp_ecs_service" {
  source                = "./modules/webapp-ecs-service"
  mandatory_tags        = module.tags.mandatory_tags
  name                  = "fsa-webapp"
  app_port              = 8080
  ecs_cluster_id        = module.ecs_cluster.cluster_id
  docker_image_url      = var.fsa_webapp_docker_image_url
  fsa_api_base_url      = module.fsa_api_ecs_service.alb_dns
  vpc_id                = module.vpc.vpc_id
  private_subnets_ids   = module.vpc.private_subnets_ids
  public_subnets_ids    = module.vpc.public_subnets_ids
  health_check_path     = "/home"
  main_domain_name      = var.main_domain_name
  static_website_domain = var.static_website_domain
}