variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

resource "aws_iam_role" "search_api_lambda_role" {
  name = "${var.project}-search-api-lambda-role"

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
    Name    = "${var.project}-search-api-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "search_api_attach_basic_execution" {
  role       = aws_iam_role.search_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "search_api_database_credentials_policy" {
  name = "${var.project}-search-api-db-credentials-policy"

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
    Name    = "${var.project}-search-api-db-credentials-policy"
  }
}

resource "aws_iam_role_policy_attachment" "search_api_attach_secrets" {
  role       = aws_iam_role.search_api_lambda_role.name
  policy_arn = aws_iam_policy.search_api_database_credentials_policy.arn
}
