variable "subnet_ids" {
  description = "Subnet IDs where the ECS tasks will run"
  type        = list(string)
}

variable "furniture_cluster_arn" {
  description = "ARN of the ECS cluster where the crawler task will run"
  type        = string
}

variable "events_invoke_ecs_role_arn" {
  description = "ARN of the IAM role that allows EventBridge to invoke ECS tasks"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the ECS tasks"
  type        = list(string)
}

resource "aws_cloudwatch_event_rule" "crawler" {
  name                = "${var.project}-crawler-event-rule"
  description         = "Run crawler"
  schedule_expression = "cron(0/7 * * * ? *)"
  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-event-rule"
  }

  state = "ENABLED"
}

resource "aws_cloudwatch_event_target" "crawler_daily_run" {
  rule      = aws_cloudwatch_event_rule.crawler.name
  arn       = var.furniture_cluster_arn
  role_arn  = var.events_invoke_ecs_role_arn
  target_id = "${var.project}-crawler-ecs-target"

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.furniture_crawler_task_definition.arn
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
      Name    = "${var.project}-crawler-task-scheduled"
      Project = var.project
    }
  }
}
