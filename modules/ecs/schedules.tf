variable "subnet_ids" {
  description = "Subnet IDs where the ECS tasks will run"
  type        = list(string)
}

resource "aws_cloudwatch_event_rule" "crawler" {
  name                = "${var.project}-crawler-event-rule"
  description         = "Run crawler"
  schedule_expression = "cron(0 * * * ? *)"

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-event-rule"
  }
}

resource "aws_cloudwatch_event_target" "crawler_daily_run" {
  rule      = aws_cloudwatch_event_rule.crawler.name
  arn       = aws_ecs_cluster.furniture_cluster.arn
  role_arn  = aws_iam_role.events_invoke_ecs_role.arn
  target_id = "${var.project}-crawler-ecs-target"

  ecs_target {
    task_definition_arn = module.furniture_crawler_task.furniture_crawler_task_definition_arn
    task_count          = 2

    capacity_provider_strategy {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
    }

    network_configuration {
      subnets          = var.subnet_ids
      security_groups  = [aws_security_group.ecs_tasks_sg.id]
      assign_public_ip = true
    }

    tags = {
      Name    = "${var.project}-crawler-task-scheduled"
      Project = var.project
    }
  }
}
