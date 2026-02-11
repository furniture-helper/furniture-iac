variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "database_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "db_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for the furniture crawler"
  type        = string
}

module "labeller_app" {
  source                           = "./labeller_app"
  database_credentials_secret_arn  = var.database_credentials_secret_arn
  database_credentials_secret_name = var.database_credentials_secret_name
  db_endpoint                      = var.db_endpoint
  s3_bucket_name                   = var.s3_bucket_name
}
