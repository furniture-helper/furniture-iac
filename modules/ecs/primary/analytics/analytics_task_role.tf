variable "project" {
  description = "Project name"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

resource "aws_iam_role" "analytics_task_role" {
  name = "${var.project}-analytics-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-analytics-task-role"
  }
}

resource "aws_iam_policy" "database_secrets_retrieval_policy" {
  name = "${var.project}-database-secrets-retrieval"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.database_credentials_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_database_secrets_retrieval_policy" {
  role       = aws_iam_role.analytics_task_role.name
  policy_arn = aws_iam_policy.database_secrets_retrieval_policy.arn
}
