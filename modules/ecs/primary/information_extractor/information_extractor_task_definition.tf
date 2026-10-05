variable "project" {
  description = "Project name"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "ecr_repo_url" {
  description = "ECR repository URL for the information extractor container image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the information extractor container"
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

variable "kafka_broker_urls" {
  description = "Comma-separated list of Kafka broker URLs"
  type        = string
}

variable "minimized_pages_bucket_name" {
  description = "Name of the S3 bucket for minimized pages"
  type        = string
}

data "aws_region" "current" {}

locals {
  container = {
    name      = "information_extractor"
    image     = "${var.ecr_repo_url}:${var.image_tag}"
    cpu       = 4096
    memory    = 8192
    essential = true

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/ecs/information_extractor"
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "AWS_REGION", value = data.aws_region.current.region },
      { name = "PG_HOST", value = var.rds_db_endpoint },
      { name = "PG_PORT", value = "5432" },
      { name = "MINIMIZED_PAGES_BUCKET_NAME", value = var.minimized_pages_bucket_name },
      { name = "KAFKA_BROKER_URLS", value = "${var.kafka_broker_urls}:9092" },
      { name = "KAFKA_BROKER_URLS", value = "${var.kafka_broker_urls}:9092" },
      { name = "PAGE_RETRIEVAL_COUNT", value = "500" },
    ]

    secrets = [
      {
        name      = "PG_USER"
        valueFrom = "${var.database_credentials_secret_arn}:username::"
      },
      {
        name      = "PG_PASSWORD"
        valueFrom = "${var.database_credentials_secret_arn}:password::"
      },
      {
        name      = "PG_DATABASE"
        valueFrom = "${var.database_credentials_secret_arn}:database_name::"
      }
    ]
  }

  container_definitions = [local.container]
}

resource "aws_ecs_task_definition" "information_extractor_task_definition" {
  family                   = "information_extractor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 8192

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = aws_iam_role.information_extractor_task_role.arn

  container_definitions = jsonencode(local.container_definitions)

  tags = {
    Project = var.project
    Name    = "information_extractor-task-definition"
  }
}

output "information_extractor_task_definition_arn" {
  value       = aws_ecs_task_definition.information_extractor_task_definition.arn
  description = "ARN of the ECS task definition for the information extractor container"
}
