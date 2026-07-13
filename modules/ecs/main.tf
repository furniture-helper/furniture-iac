terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.secondary]
    }
  }
}

moved {
  from = module.primary.module.html_minimizer_task
  to   = module.html_minimizer_task
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "primary_vpc_id" {
  description = "ID of the primary VPC"
  type        = string
}

variable "primary_public_subnet_ids" {
  description = "IDs of the primary public subnets"
  type        = list(string)
}

variable "secondary_vpc_id" {
  description = "ID of the secondary VPC"
  type        = string
}

variable "secondary_public_subnet_ids" {
  description = "IDs of the secondary public subnets"
  type        = list(string)
}

variable "crawler_s3_bucket_name" {
  description = "Name of the S3 bucket for the crawler"
  type        = string
}

variable "crawler_s3_bucket_arn" {
  description = "ARN of the S3 bucket for the crawler"
  type        = string
}

variable "html_minimizer_ecr_repo_url" {
  description = "URL of the ECR repository for the HTML minimizer"
  type        = string
}

variable "html_minimizer_s3_bucket_name" {
  description = "Name of the S3 bucket for the HTML minimizer"
  type        = string
}

variable "html_minimizer_s3_bucket_arn" {
  description = "ARN of the S3 bucket for the HTML minimizer"
  type        = string
}

variable "anchor_tree_s3_bucket_name" {
  description = "Name of the S3 bucket for the anchor tree"
  type        = string
}

variable "anchor_tree_s3_bucket_arn" {
  description = "ARN of the S3 bucket for the anchor tree"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the secret containing database credentials"
  type        = string
}

variable "rds_db_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

variable "shared_services_region" {
  description = "Region where the crawler's shared AWS services live"
  type        = string
}

variable "crawler_sqs_queue_url" {
  description = "URL of the SQS queue for the crawler"
  type        = string
}

variable "crawler_sqs_queue_arn" {
  description = "ARN of the SQS queue for the crawler"
  type        = string
}

variable "crawler_ecr_repo_url" {
  description = "URL of the ECR repository for the crawler"
  type        = string
}

variable "rds_sg_id" {
  description = "Security group ID for the RDS database"
  type        = string
}

module "primary" {
  source = "./crawler_region"

  project                         = var.project
  cluster_name                    = "${var.project}-cluster"
  cluster_tag_name                = "${var.project}-ecs-cluster"
  vpc_id                          = var.primary_vpc_id
  crawler_s3_bucket_name          = var.crawler_s3_bucket_name
  crawler_s3_bucket_arn           = var.crawler_s3_bucket_arn
  database_credentials_secret_arn = var.database_credentials_secret_arn
  rds_db_endpoint                 = var.rds_db_endpoint
  shared_services_region          = var.shared_services_region
  crawler_sqs_queue_url           = var.crawler_sqs_queue_url
  crawler_sqs_queue_arn           = var.crawler_sqs_queue_arn
  crawler_ecr_repo_url            = var.crawler_ecr_repo_url
  rds_sg_id                       = var.rds_sg_id
  subnet_ids                      = var.primary_public_subnet_ids
}

module "secondary" {
  source = "./crawler_region"
  providers = {
    aws = aws.secondary
  }

  project                         = var.project
  cluster_name                    = "${var.project}-secondary-cluster"
  cluster_tag_name                = "${var.project}-ecs-secondary-cluster"
  crawler_ecr_repo_url            = var.crawler_ecr_repo_url
  crawler_s3_bucket_arn           = var.crawler_s3_bucket_arn
  crawler_s3_bucket_name          = var.crawler_s3_bucket_name
  crawler_sqs_queue_arn           = var.crawler_sqs_queue_arn
  crawler_sqs_queue_url           = var.crawler_sqs_queue_url
  database_credentials_secret_arn = var.database_credentials_secret_arn
  rds_db_endpoint                 = var.rds_db_endpoint
  shared_services_region          = var.shared_services_region
  subnet_ids                      = var.secondary_public_subnet_ids
  vpc_id                          = var.secondary_vpc_id
}

module "html_minimizer_task" {
  source                          = "./primary/html_minimizer"
  anchor_tree_s3_bucket_arn       = var.anchor_tree_s3_bucket_arn
  anchor_tree_s3_bucket_name      = var.anchor_tree_s3_bucket_name
  database_credentials_secret_arn = var.database_credentials_secret_arn
  ecr_repo_url                    = var.html_minimizer_ecr_repo_url
  image_tag                       = "latest"
  minimized_html_s3_bucket_arn    = var.html_minimizer_s3_bucket_arn
  minimized_html_s3_bucket_name   = var.html_minimizer_s3_bucket_name
  project                         = var.project
  raw_html_s3_bucket_arn          = var.crawler_s3_bucket_arn
  raw_html_s3_bucket_name         = var.crawler_s3_bucket_name
  rds_db_endpoint                 = var.rds_db_endpoint
  task_execution_role_arn         = module.primary.task_execution_role_arn
  furniture_cluster_arn           = module.primary.ecs_cluster_arn
  security_group_ids              = [module.primary.ecs_tasks_sg_id]
  subnet_ids                      = var.primary_public_subnet_ids
}

output "ecs_primary_tasks_sg_id" {
  description = "Security group ID for ECS primary tasks"
  value       = module.primary.ecs_tasks_sg_id
}

output "ecs_secondary_tasks_sg_id" {
  description = "Security group ID for ECS secondary tasks"
  value       = module.secondary.ecs_tasks_sg_id
}
