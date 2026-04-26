variable "project" {
  description = "Project name prefix for resources"
  type        = string
}

variable "ecr_repo_url" {
  description = "ECR repository URL for the search api container image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the search api container"
  type        = string
}

variable "rds_db_endpoint" {
  description = "Endpoint of the RDS cluster"
  type        = string
}

variable "database_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing the database credentials"
  type        = string
}

resource "aws_lambda_function" "crawler_queue_manager_lambda_function" {
  # checkov:skip=CKV_AWS_117: "Cannot deploy in VPC at the moment"
  # checkov:skip=CKV_AWS_116: "Dead letter queue not required for this use case"
  # checkov:skip=CKV_AWS_173: "Environment variables do not contain sensitive data"
  # checkov:skip=CKV_AWS_272: "No clue what this even is"
  function_name = "${var.project}-searchapi-lambda"
  role          = aws_iam_role.search_api_lambda_role.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repo_url}:${var.image_tag}"
  architectures = ["arm64"]

  environment {
    variables = {
      PG_HOST                          = var.rds_db_endpoint
      PG_PORT                          = "5432"
      DATABASE_CREDENTIALS_TYPE        = "secrets_manager"
      DATABASE_CREDENTIALS_SECRET_NAME = var.database_credentials_secret_name
      PG_SSLMODE                       = "require"
    }
  }

  timeout     = 300
  memory_size = 128

  tracing_config {
    mode = "Active"
  }

  reserved_concurrent_executions = 1

  tags = {
    Project = var.project
    Name    = "${var.project}-search-api-lambda"
  }
}

output "search_api_lambda_invoke_arn" {
  value = aws_lambda_function.crawler_queue_manager_lambda_function.invoke_arn
}

output "search_api_lambda_function_name" {
  value = aws_lambda_function.crawler_queue_manager_lambda_function.function_name
}
