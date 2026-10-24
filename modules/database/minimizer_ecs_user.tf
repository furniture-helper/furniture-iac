resource "postgresql_role" "minimizer_ecs_user" {
  name  = "minimizer_ecs_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "minimizer_ecs_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.minimizer_ecs_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "minimizer_ecs_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.minimizer_ecs_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "minimizer_ecs_user_pages_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.minimizer_ecs_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["pages"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "minimizer_ecs_user_minimized_pages_table_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.minimizer_ecs_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["minimized_pages"]
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}
