terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "s3" {
  source  = "./modules/s3"
  project = var.project
}

module "iam_roles" {
  source                                = "./modules/iam_roles"
  project                               = var.project
  github_organization                   = var.github_organization
  ecr_repository_name                   = var.ecr_repository_name
  region                                = var.region
  crawler_s3_bucket_arn                 = module.s3.crawler_storage_s3_bucket_arn
  furniture_crawler_task_definition_arn = module.ecs.furniture_crawler_task_definition_arn
  ecs_cluster_arn                       = module.ecs.ecs_cluster_arn
}

module "ecr" {
  source              = "./modules/ecr"
  project             = var.project
  ecr_repository_name = var.ecr_repository_name
}

module "vpc" {
  source              = "./modules/vpc"
  project             = var.project
  vpc_cidr            = var.vpc_cidr
  availability_zone   = var.availability_zone
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "ecs" {
  source                          = "./modules/ecs"
  project                         = var.project
  furniture_crawler_ecr_repo_url  = module.ecr.furniture_crawler_ecr_repository_uri
  events_invoke_ecs_role_arn      = module.iam_roles.events_invoke_ecs_role_arn
  ecs_task_execution_role_arn     = module.iam_roles.ecs_task_execution_role_arn
  furniture_crawler_task_role_arn = module.iam_roles.furniture_crawler_task_role_arn
  subnet_id                       = module.vpc.public_subnet_id
  allow_all_egress_sg_id          = module.vpc.allow_all_egress_sg_id
  crawler_s3_bucket_name          = module.s3.crawler_storage_s3_bucket_name
  region                          = var.region
}
