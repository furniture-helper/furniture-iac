variable "crawler_ecr_repo_url" {
  description = "ECR repository URL for the furniture crawler container image"
  type        = string
}

variable "crawler_s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used by the furniture crawler"
}

variable "crawler_s3_bucket_arn" {
  description = "ARN of the S3 bucket used by the furniture crawler"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "rds_db_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

variable "crawler_sqs_queue_url" {
  description = "URL of the SQS queue for the crawler tasks"
  type        = string
}

variable "crawler_sqs_queue_arn" {
  description = "ARN of the SQS queue for the crawler tasks"
  type        = string
}

module "furniture_crawler_task" {
  source                          = "./furniture_crawler"
  project                         = var.project
  ecr_repo_url                    = var.crawler_ecr_repo_url
  s3_bucket_arn                   = var.crawler_s3_bucket_arn
  s3_bucket_name                  = var.crawler_s3_bucket_name
  task_execution_role_arn         = aws_iam_role.ecs_task_execution_role.arn
  database_credentials_secret_arn = var.database_credentials_secret_arn
  rds_db_endpoint                 = var.rds_db_endpoint
  image_tag                       = "latest"
  crawler_sqs_queue_url           = var.crawler_sqs_queue_url
  crawler_sqs_queue_arn           = var.crawler_sqs_queue_arn
}
