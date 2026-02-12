data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

resource "aws_iam_role" "amplify_service_role" {
  name = "amplify-labeller-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "amplify.amazonaws.com",
            "amplify.${data.aws_region.current.region}.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnLike = {
            "aws:SourceArn" : "arn:aws:amplify:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:apps/*"
          },
          StringEquals = {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "amplify_service_role"
  }
}

resource "aws_iam_role_policy_attachment" "amplify_ssr_policy_attachment" {
  role       = aws_iam_role.amplify_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}

resource "aws_iam_policy" "ssr_logging_policy" {
  name        = "AmplifySSRLoggingPolicy"
  description = "Allows Amplify SSR apps to push logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.labeller_log_group.arn}:*"
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "amplify_ssr_logging_policy"
  }
}
resource "aws_iam_role_policy_attachment" "ssr_logging_attach" {
  role       = aws_iam_role.amplify_service_role.name
  policy_arn = aws_iam_policy.ssr_logging_policy.arn
}

resource "aws_iam_policy" "read_secrets_policy" {
  name        = "AmplifyReadSecretsPolicy"
  description = "Allows Amplify SSR apps to read secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
    Name    = "amplify_read_secrets_policy"
  }
}

resource "aws_iam_role_policy_attachment" "read_secrets_attach" {
  role       = aws_iam_role.amplify_service_role.name
  policy_arn = aws_iam_policy.read_secrets_policy.arn
}
