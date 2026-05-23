variable "search_api_ecr_repo_url" {
  description = "URL of the ECR repository for the search API"
  type        = string
}


module "search_api" {
  source                           = "./search_api"
  ecr_repo_url                     = var.search_api_ecr_repo_url
  image_tag                        = "135ddf17558eced648c9ca5d40e36dee0a2213fd"
  project                          = var.project
  database_credentials_secret_arn  = var.database_credentials_secret_arn
  database_credentials_secret_name = var.database_credentials_name
  rds_db_endpoint                  = var.rds_db_endpoint
}

output "search_api_lambda_invoke_arn" {
  value = module.search_api.search_api_lambda_invoke_arn
}

output "search_api_lambda_name" {
  value = module.search_api.search_api_lambda_function_name
}
