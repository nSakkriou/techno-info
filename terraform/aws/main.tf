provider "aws" {
  region = "us-east-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

module "vpc_infra" {
  source = "./modules/vpc_infra"
  vpc_name = "vpc-app-php"
  availability_zone = "us-east-2"
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc_infra.vpc_id
  vpc_cidr = module.vpc_infra.vpc_cidr
}

module "rds"{
  source = "./modules/rds"
  security_group_db_id = module.security_groups.sql_security_group_id
  db_name = var.db_name
  db_password = var.db_password
  db_user = var.db_user
  subnet_id_list = [module.vpc_infra.subnet-az1-private_id, module.vpc_infra.subnet-az2-private_id]
}

module "loadbalancer_autoscaling" {
  source = "./modules/alb_auto_scaling_group"
  vpc_id = module.vpc_infra.vpc_id
  subnet_id_list = [module.vpc_infra.subnet-az1-public_id,  module.vpc_infra.subnet-az2-public_id]
  loadbalancer_security_group_id = module.security_groups.loadbalancer_security_group_id
}

module "auto_scaling_group"{
  source = "./modules/auto_scaling_group"
  available_subnets = [module.vpc_infra.subnet-az1-private_id, module.vpc_infra.subnet-az2-private_id]

  host_env = module.rds.db_host
  dbname_env = var.db_name
  user_env = var.db_user
  password_env = var.db_password

  min_instance = var.min_instance
  max_instance = var.max_instance
  desired_instance = var.desired_instance
  target_group_arn = module.loadbalancer_autoscaling.lb_target_group_arn
  ec2_security_group_id = module.security_groups.ec2_security_group_id
}