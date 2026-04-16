variable "database_credentials_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "rds_db_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

module "page_classification_pipeline" {
  source = "./page_classification_inferrence"

  database_credentials_secret_arn = var.database_credentials_arn
  rds_db_endpoint                 = var.rds_db_endpoint
  sagemaker_bucket_name           = aws_s3_bucket.sagemaker_storage.bucket
  sagemaker_role_arn              = aws_iam_role.sagemaker_execution_role.arn
}

module "information_extraction_pipeline" {
  source = "./information_extraction_inferrence"

  database_credentials_secret_arn = var.database_credentials_arn
  rds_db_endpoint                 = var.rds_db_endpoint
  sagemaker_bucket_name           = aws_s3_bucket.sagemaker_storage.bucket
  sagemaker_role_arn              = aws_iam_role.sagemaker_execution_role.arn
}
