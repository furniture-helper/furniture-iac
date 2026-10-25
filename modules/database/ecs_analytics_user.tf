resource "postgresql_role" "ecs_analytics_user" {
  name  = "ecs_analytics_user"
  login = true
  roles = ["rds_iam"]
}

resource "postgresql_grant" "ecs_analytics_user_connect" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_analytics_user.name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "ecs_analytics_user_schema_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_analytics_user.name
  schema      = "analytics"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "ecs_analytics_user_analytics_tables_write" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_analytics_user.name
  schema      = "analytics"
  object_type = "table"
  objects = [
    "classification_event",
    "success_crawler_events",
    "failed_crawler_events",
    "extraction_events",
    "minimizer_events"
  ]
  privileges = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "ecs_analytics_user_analytics_sequences_usage" {
  database    = local.db_credentials.database_name
  role        = postgresql_role.ecs_analytics_user.name
  schema      = "analytics"
  object_type = "sequence"
  objects = [
    "classification_event_id_seq",
    "success_crawler_events_id_seq",
    "failed_crawler_events_id_seq",
    "extraction_events_id_seq",
    "minimizer_events_id_seq"
  ]
  privileges = ["USAGE", "SELECT"]
}
