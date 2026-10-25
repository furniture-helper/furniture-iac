resource "postgresql_role" "crawler_queue_manager_user" {
  name  = "crawler_queue_manager_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "crawler_queue_manager_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_queue_manager_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "crawler_queue_manager_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_queue_manager_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "crawler_queue_manager_user_pages_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_queue_manager_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["pages"]
  privileges  = ["SELECT"]
}
