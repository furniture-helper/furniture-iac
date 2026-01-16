data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "furniture_rds_master_credentials"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

output "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  value       = data.aws_secretsmanager_secret_version.db_creds.arn
}

output "database_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing the database credentials"
  value       = data.aws_secretsmanager_secret_version.db_creds.secret_id
}
