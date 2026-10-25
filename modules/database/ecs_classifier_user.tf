resource "postgresql_role" "ecs_classifier_user" {
  name  = "ecs_classifier_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "ecs_classifier_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_classifier_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "ecs_classifier_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_classifier_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "ecs_classifier_user_page_classifications_table_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_classifier_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["page_classifications"]
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "ecs_classifier_user_minimized_pages_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_classifier_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["minimized_pages"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "ecs_classifier_user_pages_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_classifier_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["pages"]
  privileges  = ["SELECT"]
}
