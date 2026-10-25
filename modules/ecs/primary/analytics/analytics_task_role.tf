variable "project" {
  description = "Project name"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "rds_db_resource_id" {
  description = "Resource ID of the RDS DB instance for IAM auth"
  type        = string
}

variable "shared_services_region" {
  description = "Region where the shared RDS services live"
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

  tags = {
    Project = var.project
    Name    = "${var.project}-analytics-database-secrets-retrieval-policy"
  }
}

resource "aws_iam_role_policy_attachment" "attach_database_secrets_retrieval_policy" {
  role       = aws_iam_role.analytics_task_role.name
  policy_arn = aws_iam_policy.database_secrets_retrieval_policy.arn
}

resource "aws_iam_role_policy" "rds_iam_connect_policy" {
  name = "${var.project}-analytics-rds-iam-connect"
  role = aws_iam_role.analytics_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSIAMConnectForAnalyticsUser"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:${var.shared_services_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_db_resource_id}/${var.ecs_analytics_db_username}"
      }
    ]
  })
}
