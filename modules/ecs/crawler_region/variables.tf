variable "project" {
  description = "Project name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "cluster_tag_name" {
  description = "Name tag to apply to the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS tasks will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where the ECS tasks will run"
  type        = list(string)
}

variable "crawler_ecr_repo_urls" {
  description = "ECR repository URLs for the furniture crawler container image"
  type        = map(string)
}

variable "crawler_s3_bucket_name" {
  description = "The name of the S3 bucket used by the furniture crawler"
  type        = string
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

variable "shared_services_region" {
  description = "Region where shared dependencies like SQS, S3, and Secrets live"
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

variable "crawler_schedule_expression" {
  description = "EventBridge schedule expression for the crawler task"
  type        = string
}

variable "rds_sg_id" {
  description = "Security group ID for RDS when the crawler can reach it through security-group references"
  type        = string
  default     = null
}

variable "rds_egress_cidr_blocks" {
  description = "CIDR blocks to use for database egress when no RDS security group is provided"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
