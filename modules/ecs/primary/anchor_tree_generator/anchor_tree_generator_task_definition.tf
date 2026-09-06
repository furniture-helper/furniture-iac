variable "ecr_repo_url" {
  description = "ECR repository URL for the anchor tree generator container image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the anchor tree generator container"
  type        = string
}

variable "raw_html_s3_bucket_name" {
  description = "Name of the S3 bucket for the raw HTML storage"
  type        = string
}

variable "anchor_tree_s3_bucket_name" {
  description = "Name of the S3 bucket for boilerplate remover anchor tree"
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

data "aws_region" "current" {}

locals {
  container = {
    name      = "anchor_tree_generator"
    image     = "${var.ecr_repo_url}:${var.image_tag}"
    cpu       = 16384
    memory    = 32768
    essential = true

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/ecs/anchor_tree_generator"
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "AWS_REGION", value = data.aws_region.current.region },
      { name = "PG_HOST", value = var.rds_db_endpoint },
      { name = "PG_PORT", value = "5432" },
      { name = "CRAWLED_PAGES_BUCKET_NAME", value = var.raw_html_s3_bucket_name },
      { name = "ANCHOR_TREE_BUCKET_NAME", value = var.anchor_tree_s3_bucket_name },
      { name = "LOG_LEVEL", value = "INFO" },
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

resource "aws_ecs_task_definition" "anchor_tree_generator_task_definition" {
  family                   = "anchor_tree_generator"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 16384
  memory                   = 32768

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = aws_iam_role.anchor_tree_generator_task_role.arn

  container_definitions = jsonencode(local.container_definitions)

  tags = {
    Project = var.project
    Name    = "anchor_tree_generator_task_definition"
  }
}

output "anchor_tree_generator_task_definition_arn" {
  value       = aws_ecs_task_definition.anchor_tree_generator_task_definition.arn
  description = "ARN of the ECS task definition for the anchor tree generator"
}
