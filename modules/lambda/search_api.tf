variable "search_api_ecr_repo_url" {
  description = "URL of the ECR repository for the crawler queue manager"
  type        = string
}


module "search_api" {
  source                           = "./search_api"
  ecr_repo_url                     = var.search_api_ecr_repo_url
  image_tag                        = "5f9bb4fa881c0f678a9797dd5130edd41f2e3859"
  project                          = var.project
  database_credentials_secret_arn  = var.database_credentials_secret_arn
  database_credentials_secret_name = var.database_credentials_name
  rds_db_endpoint                  = var.rds_db_endpoint
}

