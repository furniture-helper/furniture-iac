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
  role_arn = var.events_invoke_ecs_role_arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.furniture_crawler_task_definition.arn
    task_count          = 1
    launch_type         = "FARGATE"

    network_configuration {
      subnets          = var.private_subnet_ids
      security_groups  = [var.allow_all_egress_sg_id]
      assign_public_ip = false
    }
  }
}
