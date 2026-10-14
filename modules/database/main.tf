terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.27.0"
    }
  }
}

variable "rds_endpoint" {
  description = "The endpoint of the RDS PostgreSQL database"
  type        = string
}

variable "db_iam_auth_token" {
  description = "Optional IAM authentication token for the PostgreSQL database. Generate it at runtime when needed for DB access."
  type        = string
  default     = null
  nullable    = true
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


data "aws_caller_identity" "current" {}

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

