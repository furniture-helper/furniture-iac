terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.secondary, aws.tertiary]
    }
  }
}

variable "primary_availability_zone_1" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
}

variable "primary_availability_zone_2" {
  description = "Second Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
}

variable "secondary_availability_zone_1" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
}

variable "secondary_availability_zone_2" {
  description = "Second Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
}

variable "tertiary_availability_zone_1" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
}

variable "tertiary_availability_zone_2" {
  description = "Second Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
}


module "primary_vpc" {
  source = "./region"

  availability_zone_1        = var.primary_availability_zone_1
  availability_zone_2        = var.primary_availability_zone_2
  vpc_cidr_block             = "10.0.0.0/16"
  public_subnet_cidr_blocks  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidr_blocks = ["10.0.2.0/24", "10.0.3.0/24"]
}

module "secondary_vpc" {
  source = "./region"
  providers = {
    aws = aws.secondary
  }
  availability_zone_1        = var.secondary_availability_zone_1
  availability_zone_2        = var.secondary_availability_zone_2
  vpc_cidr_block             = "10.1.0.0/16"
  public_subnet_cidr_blocks  = ["10.1.0.0/24", "10.1.1.0/24"]
  private_subnet_cidr_blocks = ["10.1.2.0/24", "10.1.3.0/24"]
}

module "tertiary_vpc" {
  source = "./region"
  providers = {
    aws = aws.tertiary
  }
  availability_zone_1        = var.tertiary_availability_zone_1
  availability_zone_2        = var.tertiary_availability_zone_2
  vpc_cidr_block             = "10.2.0.0/16"
  public_subnet_cidr_blocks  = ["10.2.0.0/24", "10.2.1.0/24"]
  private_subnet_cidr_blocks = ["10.2.2.0/24", "10.2.3.0/24"]
}

output "primary_vpc_id" {
  value = module.primary_vpc.vpc_id
}

output "secondary_vpc_id" {
  value = module.secondary_vpc.vpc_id
}

output "primary_public_subnet_ids" {
  value = module.primary_vpc.public_subnet_ids
}

output "primary_private_subnet_ids" {
  value = module.primary_vpc.private_subnet_ids
}

output "secondary_public_subnet_ids" {
  value = module.secondary_vpc.public_subnet_ids
}

output "tertiary_vpc_id" {
  value = module.tertiary_vpc.vpc_id
}

output "tertiary_public_subnet_ids" {
  value = module.tertiary_vpc.public_subnet_ids
}
