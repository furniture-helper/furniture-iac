variable "navigation_timeout_s" {
  description = "Timeout in seconds for navigation tasks"
  type        = number
}

variable "furniture_db_name" {
  description = "Name of the furniture database"
  type        = string
}

module "furniture_crawler_task" {
  source                          = "./furniture_crawler"
  project                         = var.project
  ecr_repo_urls                   = var.crawler_ecr_repo_urls
  s3_bucket_arn                   = var.crawler_s3_bucket_arn
  s3_bucket_name                  = var.crawler_s3_bucket_name
  task_execution_role_arn         = aws_iam_role.ecs_task_execution_role.arn
  database_credentials_secret_arn = var.database_credentials_secret_arn
  crawler_db_username             = var.crawler_db_username
  rds_db_endpoint                 = var.rds_db_endpoint
  rds_db_resource_id              = var.rds_db_resource_id
  shared_services_region          = var.shared_services_region
  image_tag                       = "latest"
  crawler_sqs_queue_url           = var.crawler_sqs_queue_url
  crawler_sqs_queue_arn           = var.crawler_sqs_queue_arn
  crawler_schedule_expression     = var.crawler_schedule_expression
  events_invoke_ecs_role_arn      = aws_iam_role.events_invoke_ecs_role.arn
  furniture_cluster_arn           = aws_ecs_cluster.furniture_cluster.arn
  security_group_ids              = [aws_security_group.ecs_tasks_sg.id]
  subnet_ids                      = var.subnet_ids
  kafka_public_ip                 = var.kafka_public_ip
  navigation_timeout_s            = var.navigation_timeout_s
  furniture_db_name               = var.furniture_db_name
}
