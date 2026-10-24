resource "postgresql_role" "anchor_tree_generator_user" {
  name  = "anchor_tree_generator_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "anchor_tree_generator_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.anchor_tree_generator_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "anchor_tree_generator_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.anchor_tree_generator_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "anchor_tree_generator_user_pages_table_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.anchor_tree_generator_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["pages"]
  privileges  = ["SELECT"]
}
