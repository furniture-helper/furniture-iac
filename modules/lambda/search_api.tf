variable "search_api_ecr_repo_url" {
  description = "URL of the ECR repository for the search API"
  type        = string
}

variable "frontend_origin" {
  description = "The allowed origin for CORS configuration"
  type        = string
}

variable "s3_region" {
  description = "The AWS region where the S3 buckets are located"
  type        = string
}

variable "crawler_storage_s3_bucket" {
  description = "The name of the S3 bucket for crawler storage"
  type        = string
}

variable "minimized_pages_s3_bucket" {
  description = "The name of the S3 bucket for minimized pages"
  type        = string
}

module "search_api" {
  source                           = "./search_api"
  ecr_repo_url                     = var.search_api_ecr_repo_url
  image_tag                        = "83089ff812e73d04df8b4d864ba8db9d12c13b33"
  project                          = var.project
  database_credentials_secret_arn  = var.database_credentials_secret_arn
  database_credentials_secret_name = var.database_credentials_name
  rds_db_endpoint                  = var.rds_db_endpoint
  frontend_origin                  = var.frontend_origin
  s3_region                        = var.s3_region
  crawler_storage_s3_bucket        = var.crawler_storage_s3_bucket
  minimized_pages_s3_bucket        = var.minimized_pages_s3_bucket
}

output "search_api_lambda_invoke_arn" {
  value = module.search_api.search_api_lambda_invoke_arn
}

output "search_api_lambda_name" {
  value = module.search_api.search_api_lambda_function_name
}
