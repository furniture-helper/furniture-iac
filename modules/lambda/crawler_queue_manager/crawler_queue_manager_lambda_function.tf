variable "project" {
  description = "Project name prefix for resources"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the Lambda function"
  type        = list(string)
}

variable "ecr_repo_url" {
  description = "ECR repository URL for the crawler queue manager container image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the crawler queue manager container"
  type        = string
}

variable "rds_cluster_endpoint" {
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
  function_name = "${var.project}-crawler-queue-manager-lambda"
  role          = aws_iam_role.crawler_queue_manager_lambda_role.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repo_url}:${var.image_tag}"
  architectures = ["arm64"]

  vpc_config {
    subnet_ids         = var.public_subnet_ids
    security_group_ids = [aws_security_group.crawler_queue_manager_lambda_sg.id]
  }

  environment {
    variables = {
      PG_HOST                          = var.rds_cluster_endpoint
      PG_PORT                          = "5432"
      SQS_QUEUE_URL                    = var.crawler_sqs_queue_url
      FETCH_AMOUNT                     = "5"
      DATABASE_CREDENTIALS_TYPE        = "secrets_manager"
      DATABASE_CREDENTIALS_SECRET_NAME = var.database_credentials_secret_name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.crawler_queue_manager_lambda_vpc_access]

  timeout     = 300
  memory_size = 128
}
