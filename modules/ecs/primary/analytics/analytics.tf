variable "ecr_repo_url" {
  description = "ECR repository URL for the analytics container image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the analytics container"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "rds_db_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

variable "database_credentials_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing database credentials"
  type        = string
}

variable "kafka_brokers" {
  description = "Comma-separated list of Kafka broker addresses"
  type        = string
}

data "aws_region" "current" {}

locals {
  container = {
    name      = "analytics"
    image     = "${var.ecr_repo_url}:${var.image_tag}"
    cpu       = 1024
    memory    = 2048
    essential = true

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/ecs/analytics"
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "PG_HOST", value = var.rds_db_endpoint },
      { name = "PG_PORT", value = "5432" },
      { name = "DATABASE_CREDENTIALS_TYPE", value = "secrets_manager" },
      { name = "DATABASE_CREDENTIALS_SECRET_NAME", value = var.database_credentials_secret_name },
      { name = "PG_SSLMODE", value = "require" },
      { name = "PG_SSLMODE", value = "require" },
      { name = "MAXIMUM_RUNTIME_SECS", value = "60" },
      { name = "KAFKA_BROKERS", value = var.kafka_brokers }
    ]
  }

  container_definitions = [local.container]
}

resource "aws_ecs_task_definition" "analytics_task_definition" {
  family                   = "analytics"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = aws_iam_role.analytics_task_role.arn

  container_definitions = jsonencode(local.container_definitions)

  tags = {
    Project = var.project
    Name    = "analytics-task-definition"
  }
}

output "analytics_task_definition_arn" {
  value       = aws_ecs_task_definition.analytics_task_definition.arn
  description = "ARN of the ECS task definition for the analytics container"
}
