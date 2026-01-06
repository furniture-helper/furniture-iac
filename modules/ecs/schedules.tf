variable "subnet_id" {
  description = "Subnet ID where the ECS tasks will be launched"
  type        = string
}


locals {
  crawler_targets = jsondecode(file("./${path.module}/crawler_schedule.json"))
}

resource "aws_cloudwatch_event_rule" "crawler" {
  for_each            = local.crawler_targets
  name                = "${var.project}-${each.key}-crawl"
  description         = "Run crawler for ${each.value.url}"
  schedule_expression = each.value.schedule

  tags = {
    Project = var.project
    Name    = "${var.project}-${each.key}-event-rule"
  }
}

resource "aws_cloudwatch_event_target" "crawler_daily_run" {
  for_each = local.crawler_targets

  rule      = aws_cloudwatch_event_rule.crawler[each.key].name
  arn       = aws_ecs_cluster.furniture_cluster.arn
  role_arn  = aws_iam_role.events_invoke_ecs_role.arn
  target_id = each.key

  ecs_target {
    task_definition_arn = module.furniture_crawler_task.furniture_crawler_task_definition_arn
    task_count          = 1

    capacity_provider_strategy {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
    }

    network_configuration {
      subnets          = [var.subnet_id]
      security_groups  = [aws_security_group.ecs_tasks_sg.id]
      assign_public_ip = true
    }
  }

  input = jsonencode({
    containerOverrides = [
      {
        name = "furniture-crawler",
        environment = [
          { name = "START_URL", value = each.value.url },
        ]
      }
    ]
  })
}
