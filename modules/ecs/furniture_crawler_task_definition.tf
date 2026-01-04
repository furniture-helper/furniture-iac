data "aws_region" "current" {}

locals {
  container = {
    name      = "furniture-crawler"
    image     = "${var.furniture_crawler_ecr_repo_url}:${var.furniture_crawler_image_tag}"
    cpu       = 1024
    memory    = 2048
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
      {
        name  = "AWS_S3_BUCKET"
        value = var.crawler_s3_bucket_name
      },
      {
        name  = "AWS_REGION"
        value = data.aws_region.current.region
      },
      {
        name  = "PAGE_STORAGE"
        value = "LocalStorage"
      },
      {
        name  = "MAX_REQUESTS_PER_CRAWL"
        value = "100"
      }
    ]

  }

  container_definitions = [local.container]
}

resource "aws_ecs_task_definition" "furniture_crawler_task_definition" {
  family                   = "furniture_crawler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.furniture_crawler_task_role_arn

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
