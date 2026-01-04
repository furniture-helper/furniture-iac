resource "aws_cloudwatch_log_group" "furniture_crawler_log_group" {
  name              = "/aws/ecs/furniture-crawler"
  retention_in_days = 14
  tags = {
    Project = var.project
    Name    = "${var.project}-furniture-crawler-log-group"
  }
}

locals {
  derived_ecs_task_execution_role_name = length(var.ecs_task_execution_role_arn) == 0 ? var.ecs_task_execution_role_arn : split("/", var.ecs_task_execution_role_arn)[1]
}

data "aws_iam_role" "exec" {
  count = local.derived_ecs_task_execution_role_name == "" ? 0 : 1
  name  = local.derived_ecs_task_execution_role_name
}

resource "aws_iam_role_policy" "ecs_logs_policy" {
  count = local.derived_ecs_task_execution_role_name == "" ? 0 : 1
  name  = "${local.derived_ecs_task_execution_role_name}-ecs-logs"
  role  = data.aws_iam_role.exec[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/ecs/furniture-crawler:*"
      }
    ]
  })
}
