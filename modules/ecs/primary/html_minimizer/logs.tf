data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "html_minimizer_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group retention is set to 14 days only for cost management"
  # checkov:skip=CKV_AWS_158: "KMS encryption is not required for this log group"
  name              = "/aws/ecs/html_minimizer"
  retention_in_days = 14
  tags = {
    Project = var.project
    Name    = "${var.project}-html-minimizer-log-group"
  }
}

locals {
  derived_ecs_task_execution_role_name = length(var.task_execution_role_arn) > 0 ? split("/", var.task_execution_role_arn)[1] : ""
}

resource "aws_iam_role_policy" "ecs_logs_policy" {
  name = "${local.derived_ecs_task_execution_role_name}-ecs-html-minimizer-logs"
  role = local.derived_ecs_task_execution_role_name

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
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/html_minimizer:*"
      }
    ]
  })
}
