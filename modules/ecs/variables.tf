variable "project" {
  description = "Project name"
  type        = string
}

variable "furniture_crawler_ecr_repo_url" {
  description = "ECR repository URL for the furniture crawler"
  type        = string
}

variable "furniture_crawler_image_tag" {
  description = "Image tag for the furniture crawler container"
  type        = string
  default     = "latest"
}

variable "events_invoke_ecs_role_arn" {
  description = "ARN of the IAM role that allows EventBridge to invoke ECS tasks"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "furniture_crawler_task_role_arn" {
  description = "ARN of the furniture crawler ECS task role"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS tasks"
  type        = list(string)
}

variable "allow_all_egress_sg_id" {
  description = "Security group ID that allows all egress traffic"
  type        = string
}

variable "crawler_s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used by the furniture crawler"
}

variable "region" {
  description = "AWS region"
  type        = string
}
