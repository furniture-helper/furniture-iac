variable "project" {
  description = "The name of the project"
  type        = string
}

resource "random_password" "metabase_user_password" {
  length           = 32
  special          = true
  override_special = "!@#%^*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "metabase_user_db_credentials" {
  # checkov:skip=CKV_AWS_149: "KMS key is not specified, using default AWS managed key for Secrets Manager"
  # checkov:skip=CKV2_AWS_57: "Automatic rotation is not required for this secret"
  name = "metabase_user_db_credentials"

  tags = {
    Project = var.project
    Name    = "metabase_user_db_credentials"
  }
}

resource "aws_secretsmanager_secret_version" "metabase_user_db_credentials" {
  secret_id = aws_secretsmanager_secret.metabase_user_db_credentials.id
  secret_string = jsonencode({
    username = "metabase_user"
    password = random_password.metabase_user_password.result
  })
}

resource "postgresql_role" "metabase_user" {
  name     = "metabase_user"
  login    = true
  password = random_password.metabase_user_password.result
}

resource "postgresql_grant" "metabase_user_db_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.metabase_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "metabase_user_metabase_db_connect" {
  provider    = postgresql.metabase
  database    = "metabase"
  role        = postgresql_role.metabase_user.name
  object_type = "database"
  privileges  = ["CONNECT", "CREATE"]
}

resource "postgresql_grant" "metabase_user_schema_usage" {
  for_each    = toset(["public", "analytics"])
  database    = local.db_credentials.database_name
  role        = postgresql_role.metabase_user.name
  schema      = each.key
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "metabase_user_metabase_db_schema_usage" {
  provider    = postgresql.metabase
  database    = "metabase"
  role        = postgresql_role.metabase_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "metabase_user_analytics_select" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.metabase_user.name
  schema      = "analytics"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "metabase_user_public" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.metabase_user.name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "metabase_user_metabase_db_public" {
  provider    = postgresql.metabase
  database    = "metabase"
  role        = postgresql_role.metabase_user.name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

output "metabase_user" {
  value = postgresql_role.metabase_user.name
}

output "metabase_user_db_credentials_secret_arn" {
  value = aws_secretsmanager_secret.metabase_user_db_credentials.arn
}
