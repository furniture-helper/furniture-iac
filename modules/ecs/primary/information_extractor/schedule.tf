data "aws_caller_identity" "current" {}

variable "subnet_ids" {
  description = "Subnet IDs where the ECS tasks will run"
  type        = list(string)
}

variable "furniture_cluster_arn" {
  description = "ARN of the ECS cluster where the information extractor task will run"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the ECS tasks"
  type        = list(string)
}

resource "aws_iam_role" "events_invoke_ecs_role" {
  name = "${var.project}-information-extractor-events-invoke-ecs-${data.aws_region.current.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-information-extractor-events-invoke-ecs-role-${data.aws_region.current.region}"
  }
}

resource "aws_iam_role_policy" "events_invoke_ecs_policy" {
  role = aws_iam_role.events_invoke_ecs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRunTask"
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = [
          aws_ecs_task_definition.information_extractor_task_definition.arn
        ]
        Condition = {
          StringEquals = {
            "ecs:cluster" = var.furniture_cluster_arn
          }
        }
      },
      {
        Sid    = "AllowPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          var.task_execution_role_arn,
          aws_iam_role.information_extractor_task_role.arn
        ]
      },
      {
        Sid    = "AllowTaggingTasks"
        Effect = "Allow"
        Action = [
          "ecs:TagResource"
        ]
        Resource = [
          "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task/*"
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "information_extractor_event_rule" {
  name                = "${var.project}-information-extractor-event-rule"
  description         = "Run information extractor every 30 minutes"
  schedule_expression = "rate(30 minutes)"
  tags = {
    Project = var.project
    Name    = "${var.project}-information-extractor-event-rule"
  }

  state = "ENABLED"
}

resource "aws_cloudwatch_event_target" "information_extractor_ecs_target" {
  rule      = aws_cloudwatch_event_rule.information_extractor_event_rule.name
  arn       = var.furniture_cluster_arn
  role_arn  = aws_iam_role.events_invoke_ecs_role.arn
  target_id = "${var.project}-information-extractor-ecs-target"

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.information_extractor_task_definition.arn
    task_count          = 1

    capacity_provider_strategy {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
    }

    network_configuration {
      subnets          = var.subnet_ids
      security_groups  = var.security_group_ids
      assign_public_ip = true
    }

    tags = {
      Name    = "${var.project}-information-extractor-task-scheduled"
      Project = var.project
    }
  }
}
