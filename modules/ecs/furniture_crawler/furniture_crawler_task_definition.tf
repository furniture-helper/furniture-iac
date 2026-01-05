variable "ecr_repo_url" {
  description = "ECR repository URL for the furniture crawler container image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the furniture crawler container"
  type        = string
  default     = "latest"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for the furniture crawler"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

data "aws_region" "current" {}

locals {
  container = {
    name      = "furniture-crawler"
    image     = "${var.ecr_repo_url}:${var.image_tag}"
    cpu       = 2048
    memory    = 8192
    essential = true

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/ecs/furniture-crawler"
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      { name = "AWS_S3_BUCKET", value = var.s3_bucket_name },
      { name = "AWS_REGION", value = data.aws_region.current.region },
      { name = "PAGE_STORAGE", value = "LocalStorage" },
      { name = "MAX_REQUESTS_PER_CRAWL", value = "100" }
    ]

  }

  container_definitions = [local.container]
}

resource "aws_ecs_task_definition" "furniture_crawler_task_definition" {
  family                   = "furniture_crawler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 8192

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = aws_iam_role.furniture_crawler_task_role.arn

  container_definitions = jsonencode(local.container_definitions)

  tags = {
    Project = var.project
    Name    = "furniture_crawler_task_definition"
  }
}

output "furniture_crawler_task_definition_arn" {
  value       = aws_ecs_task_definition.furniture_crawler_task_definition.arn
  description = "ARN of the ECS task definition for the furniture crawler"
}
