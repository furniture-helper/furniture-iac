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
  vpc_cidr            = var.vpc_cidr
  availability_zone   = var.availability_zone
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "ecs" {
  source                 = "./modules/ecs"
  project                = var.project
  subnet_id              = module.vpc.public_subnet_id
  allow_all_egress_sg_id = module.vpc.allow_all_egress_sg_id
  crawler_s3_bucket_name = module.s3.crawler_storage_s3_bucket_name
  crawler_ecr_repo_url   = module.ecr.furniture_crawler_ecr_repo_uri
  crawler_s3_bucket_arn  = module.s3.crawler_storage_s3_bucket_arn
}

module "github_actions" {
  source              = "./modules/github_actions"
  project             = var.project
  github_organization = var.github_organization
  crawler_repo_arn    = module.ecr.furniture_crawler_ecr_repo_arn
}
