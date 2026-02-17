variable "crawler_sqs_queue_arn" {
  description = "ARN of the SQS queue for the crawler tasks"
  type        = string
}

variable "crawler_ecr_repo_url" {
  description = "URL of the ECR repository for the crawler queue manager"
  type        = string
}

variable "project" {
  description = "Project name prefix for resources"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "crawler_sqs_queue_url" {
  description = "URL of the SQS queue for the crawler tasks"
  type        = string
}

variable "database_credentials_name" {
  description = "Name of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "rds_db_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

module "crawler_queue_manager" {
  source                           = "./crawler_queue_manager"
  crawler_sqs_queue_arn            = var.crawler_sqs_queue_arn
  ecr_repo_url                     = var.crawler_ecr_repo_url
  image_tag                        = "c424fc1b25eb7a26826b0bb6e7c2b9501a8b8e41"
  project                          = var.project
  database_credentials_secret_arn  = var.database_credentials_secret_arn
  crawler_sqs_queue_url            = var.crawler_sqs_queue_url
  database_credentials_secret_name = var.database_credentials_name
  rds_db_endpoint                  = var.rds_db_endpoint
}

