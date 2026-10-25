variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "search_api_db_username" {
  description = "Database username used by the search API workload"
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

data "aws_caller_identity" "current" {}

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

resource "aws_iam_policy" "search_api_read_access_to_s3_buckets" {
  name = "${var.project}-search-api-read-s3-buckets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListBuckets"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.crawler_storage_s3_bucket}",
          "arn:aws:s3:::${var.minimized_pages_s3_bucket}"
        ]
      },
      {
        Sid    = "AllowReadObjects"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::${var.crawler_storage_s3_bucket}/*",
          "arn:aws:s3:::${var.minimized_pages_s3_bucket}/*"
        ]
      }
    ]
  })
  tags = {
    Project = var.project
    Name    = "${var.project}-search-api-read-s3-buckets-policy"
  }
}

resource "aws_iam_role_policy_attachment" "search_api_attach_s3_read_access" {
  role       = aws_iam_role.search_api_lambda_role.name
  policy_arn = aws_iam_policy.search_api_read_access_to_s3_buckets.arn
}

resource "aws_iam_policy" "search_api_rds_iam_connect_policy" {
  name = "${var.project}-search-api-rds-iam-connect"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRDSIAMConnectForSearchAPIUser"
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = "arn:aws:rds-db:${var.shared_services_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_db_resource_id}/${var.search_api_db_username}"
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-search-api-rds-iam-connect-policy"
  }
}

resource "aws_iam_role_policy_attachment" "search_api_attach_rds_iam_connect" {
  role       = aws_iam_role.search_api_lambda_role.name
  policy_arn = aws_iam_policy.search_api_rds_iam_connect_policy.arn
}
