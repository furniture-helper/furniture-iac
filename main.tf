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

module "iam_roles" {
  source              = "./modules/iam_roles"
  project             = var.project
  github_organization = var.github_organization
  ecr_repository_name = var.ecr_repository_name
  region              = var.region
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
