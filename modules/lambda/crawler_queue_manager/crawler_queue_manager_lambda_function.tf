variable "project" {
  description = "Project name prefix for resources"
  type        = string
}

variable "ecr_repo_url" {
  description = "ECR repository URL for the crawler queue manager container image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the crawler queue manager container"
  type        = string
}

variable "rds_db_endpoint" {
  description = "Endpoint of the RDS cluster"
  type        = string
}

variable "crawler_sqs_queue_url" {
  description = "URL of the SQS queue for the crawler tasks"
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
  function_name = "${var.project}-crawler-queue-manager-lambda"
  role          = aws_iam_role.crawler_queue_manager_lambda_role.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repo_url}:${var.image_tag}"
  architectures = ["arm64"]

  environment {
    variables = {
      PG_HOST                          = var.rds_db_endpoint
      PG_PORT                          = "5432"
      SQS_QUEUE_URL                    = var.crawler_sqs_queue_url
      FETCH_AMOUNT                     = "500"
      DATABASE_CREDENTIALS_TYPE        = "secrets_manager"
      DATABASE_CREDENTIALS_SECRET_NAME = var.database_credentials_secret_name
      SQS_QUEUE_THRESHOLD              = "99999"
      DELETION_INTERVAL_DAYS           = "3"
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
    Name    = "${var.project}-crawler-queue-manager-lambda"
  }
}
