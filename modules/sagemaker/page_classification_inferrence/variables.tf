variable "sagemaker_role_arn" { type = string }
variable "rds_db_endpoint" { type = string }
variable "database_credentials_secret_arn" { type = string }
variable "sagemaker_bucket_name" { type = string }

variable "page_classification_schedule_expression" {
  type    = string
  default = "cron(0 0 * * ? *)"
}

