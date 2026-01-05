resource "aws_iam_role" "events_invoke_ecs_role" {
  name = "${var.project}-events-invoke-ecs"

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
    Name    = "${var.project}-events-invoke-ecs-role"
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
          module.furniture_crawler_task.furniture_crawler_task_definition_arn,
        ]
        Condition = {
          StringEquals = {
            "ecs:cluster" = aws_ecs_cluster.furniture_cluster.arn
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
          aws_iam_role.ecs_task_execution_role.arn,
          module.furniture_crawler_task.furniture_crawler_task_role_arn
        ]
      }
    ]
  })
}

output "events_invoke_ecs_role_arn" {
  value       = aws_iam_role.events_invoke_ecs_role.arn
  description = "ARN of the IAM role that allows EventBridge to invoke ECS tasks"
}
