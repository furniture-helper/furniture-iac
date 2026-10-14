data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "furniture_rds_master_credentials"
}

data "aws_region" "current" {}

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

output "token_generation_command" {
  description = "Example command to generate an auth token"
  value       = "$env:TF_VAR_db_iam_auth_token = aws rds generate-db-auth-token --hostname ${aws_db_instance.db_instance_v2.address} --port 5432 --region ${data.aws_region.current.name} --username terraform_user"
}
