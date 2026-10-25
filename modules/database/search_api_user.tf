resource "postgresql_role" "search_api_user" {
  name  = "search_api_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "search_api_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "search_api_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "search_api_user_page_inferred_labels_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["page_inferred_labels"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "search_api_user_page_classifications_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["page_classifications"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "search_api_user_product_price_history_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["product_price_history"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "search_api_user_products_embeddings_finetuned_768_2_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["products_embeddings_finetuned_768_2"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "search_api_user_products_embeddings_768_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["products_embeddings_768"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "search_api_user_pages_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["pages"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "search_api_user_minimized_pages_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["minimized_pages"]
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "search_api_user_matching_products_table_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.search_api_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["matching_products"]
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}
