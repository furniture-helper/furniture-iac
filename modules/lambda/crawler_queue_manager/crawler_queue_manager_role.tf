variable "crawler_sqs_queue_arn" {
  description = "ARN of the SQS queue for the crawler tasks"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

resource "aws_iam_role" "crawler_queue_manager_lambda_role" {
  name = "${var.project}-crawler-queue-manager-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-queue-manager-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "crawler_queue_manager_lambda_basic_execution" {
  role       = aws_iam_role.crawler_queue_manager_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "crawler_queue_manager_lambda_sqs_write_policy" {
  name        = "${var.project}-crawler-queue-manager-lambda-sqs-policy"
  description = "Allows Lambda to send messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.crawler_sqs_queue_arn
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-queue-manager-lambda-sqs-policy"
  }
}

resource "aws_iam_role_policy_attachment" "crawler_queue_manager_lambda_sqs_write" {
  role       = aws_iam_role.crawler_queue_manager_lambda_role.name
  policy_arn = aws_iam_policy.crawler_queue_manager_lambda_sqs_write_policy.arn
}

resource "aws_iam_policy" "crawler_queue_manager_database_credentials_policy" {
  name = "${var.project}-crawler-queue-manager-db-credentials-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = var.database_credentials_secret_arn
    }]
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-queue-manager-db-credentials-policy"
  }
}

resource "aws_iam_role_policy_attachment" "attach_secrets" {
  role       = aws_iam_role.crawler_queue_manager_lambda_role.name
  policy_arn = aws_iam_policy.crawler_queue_manager_database_credentials_policy.arn
}
