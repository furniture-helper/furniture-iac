resource "postgresql_role" "ecs_embedder_user" {
  name  = "ecs_embedder_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "ecs_embedder_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_embedder_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "ecs_embedder_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_embedder_user.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "ecs_embedder_user_public_read" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_embedder_user.name
  schema      = "public"
  object_type = "table"
  objects = [
    "page_inferred_labels",
    "pages",
    "page_classifications",
  ]
  privileges = ["SELECT"]
}

resource "postgresql_grant" "ecs_embedder_user_products_embeddings_finetuned_768_2_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_embedder_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["products_embeddings_finetuned_768_2"]
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "ecs_embedder_user_products_embeddings_finetuned_768_3_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_embedder_user.name
  schema      = "public"
  object_type = "table"
  objects     = ["products_embeddings_finetuned_768_3"]
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}
