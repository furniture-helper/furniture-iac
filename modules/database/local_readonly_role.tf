resource "postgresql_role" "local_readonly_user" {
  name  = "local_readonly_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "db_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.local_readonly_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "schema_usage" {
  for_each    = toset(["public", "analytics"])
  database    = local.db_credentials.database_name
  role        = postgresql_role.local_readonly_user.name
  schema      = each.value
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "table_select" {
  for_each    = toset(["public", "analytics"])
  database    = local.db_credentials.database_name
  role        = postgresql_role.local_readonly_user.name
  schema      = each.value
  object_type = "table"
  privileges  = ["SELECT"]
}
