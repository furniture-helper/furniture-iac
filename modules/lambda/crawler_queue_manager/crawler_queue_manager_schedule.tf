resource "aws_cloudwatch_event_rule" "crawler_queue_manager_schedule" {
  name                = "${var.project}-crawler-queue-manager-schedule-event-rule"
  description         = "Triggers lambda function every hour"
  schedule_expression = "cron(0/15 * * * ? *)"

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-queue-manager-hourly-event-rule"
  }
}

resource "aws_cloudwatch_event_target" "check_every_hour" {
  rule      = aws_cloudwatch_event_rule.crawler_queue_manager_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.crawler_queue_manager_lambda_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crawler_queue_manager_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.crawler_queue_manager_schedule.arn
}
