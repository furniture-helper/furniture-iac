variable "subnet_id" {
  description = "Subnet ID where the ECS tasks will be launched"
  type        = string
}

variable "allow_all_egress_sg_id" {
  description = "Security group ID that allows all egress traffic"
  type        = string
}

resource "aws_cloudwatch_event_rule" "daily_run" {
  name                = "${var.project}-daily-run"
  description         = "Run ECS task once per day"
  schedule_expression = "cron(0 2 * * ? *)"

  tags = {
    Project = var.project
    Name    = "${var.project}-daily-run-event-rule"
  }
}

resource "aws_cloudwatch_event_target" "crawler_daily_run" {
  rule     = aws_cloudwatch_event_rule.daily_run.name
  arn      = aws_ecs_cluster.furniture_cluster.arn
  role_arn = aws_iam_role.events_invoke_ecs_role.arn

  ecs_target {
    task_definition_arn = module.furniture_crawler_task.furniture_crawler_task_definition_arn
    task_count          = 1
    launch_type         = "FARGATE"

    network_configuration {
      subnets          = [var.subnet_id]
      security_groups  = [var.allow_all_egress_sg_id]
      assign_public_ip = true
    }
  }
}
