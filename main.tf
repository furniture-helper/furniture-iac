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

module "ecr" {
  source  = "./modules/ecr"
  project = var.project
}

module "vpc" {
  source              = "./modules/vpc"
  project             = var.project
  availability_zone_1 = var.availability_zone_1
  availability_zone_2 = var.availability_zone_2
}

module "ecs" {
  source                          = "./modules/ecs"
  project                         = var.project
  subnet_ids                      = module.vpc.public_subnet_ids
  vpc_id                          = module.vpc.vpc_id
  crawler_s3_bucket_name          = module.s3.crawler_storage_s3_bucket_name
  crawler_ecr_repo_url            = module.ecr.furniture_crawler_ecr_repo_uri
  crawler_s3_bucket_arn           = module.s3.crawler_storage_s3_bucket_arn
  rds_sg_id                       = module.rds.rds_sg_id
  database_credentials_secret_arn = module.rds.database_credentials_secret_arn
  rds_cluster_endpoint            = module.rds.cluster_endpoint
}

module "github_actions" {
  source              = "./modules/github_actions"
  project             = var.project
  github_organization = var.github_organization
  crawler_repo_arn    = module.ecr.furniture_crawler_ecr_repo_arn
}

module "rds" {
  source                   = "./modules/rds"
  project                  = var.project
  vpc_id                   = module.vpc.vpc_id
  ecs_tasks_sg_id          = module.ecs.ecs_tasks_sg_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  public_subnet_ids        = module.vpc.public_subnet_ids
  allow_public_connections = true
}

output "database_writer_endpoint" {
  description = "RDS Cluster Writer Endpoint"
  value       = module.rds.cluster_endpoint
}
