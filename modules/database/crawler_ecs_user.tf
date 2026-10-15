resource "postgresql_role" "crawler_ecs_user" {
  name  = "crawler_ecs_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "crawler_ecs_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "crawler_ecs_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "crawler_ecs_user_pages_table_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["pages"]
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "crawler_ecs_user_crawl_logs_table_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["crawl_logs"]
  privileges  = ["INSERT"]
}

resource "postgresql_grant" "crawler_ecs_user_crawl_logs_sequence_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  schema      = "public"
  object_type = "sequence"
  objects     = ["crawl_logs_log_id_seq"]
  privileges  = ["USAGE", "SELECT"]
}

resource "postgresql_grant" "crawler_ecs_user_page_classifications_table_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["page_classifications"]
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "crawler_ecs_user_page_inferred_labels_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["page_inferred_labels"]
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "crawler_ecs_product_price_history_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.crawler_ecs_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["product_price_history"]
  privileges  = ["INSERT"]
}
