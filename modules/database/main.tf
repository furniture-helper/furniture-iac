terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.27.0"
    }
  }
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "rds_endpoint" {
  description = "The endpoint of the RDS PostgreSQL database"
  type        = string
}

variable "db_iam_auth_token" {
  description = "The IAM authentication token for the PostgreSQL database"
  type        = string
}

variable "database_credentials_secret_name" {
  description = "The name of the AWS Secrets Manager secret containing the database credentials"
  type        = string
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = var.database_credentials_secret_name
}

data "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string)
}

provider "postgresql" {
  scheme   = "awspostgres"
  host     = var.rds_endpoint
  port     = 5432
  database = local.db_credentials.database_name
  username = "terraform_user"
  password = var.db_iam_auth_token
  sslmode  = "require"

  superuser = false
}

provider "postgresql" {
  alias    = "metabase"
  scheme   = "awspostgres"
  host     = var.rds_endpoint
  port     = 5432
  database = "metabase"
  username = "terraform_user"
  password = var.db_iam_auth_token
  sslmode  = "require"

  superuser = false
}

output "crawler_db_username" {
  value = postgresql_role.crawler_ecs_user.name
}

output "minimizer_db_username" {
  value = postgresql_role.minimizer_ecs_user.name
}

output "anchor_tree_generator_db_username" {
  value = postgresql_role.anchor_tree_generator_user.name
}

output "ecs_classifier_db_username" {
  value = postgresql_role.ecs_classifier_user.name
}

output "ecs_extractor_db_username" {
  value = postgresql_role.ecs_extractor_user.name
}

output "ecs_analytics_db_username" {
  value = postgresql_role.ecs_analytics_user.name
}

output "furniture_db_name" {
  value = local.db_credentials.database_name
}
