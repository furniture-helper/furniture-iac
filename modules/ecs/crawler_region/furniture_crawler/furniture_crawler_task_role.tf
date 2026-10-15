variable "project" {
  description = "Project name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket used by the furniture crawler"
  type        = string
}

variable "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "crawler_db_username" {
  description = "Database username used by crawler workloads"
  type        = string
}

variable "crawler_sqs_queue_arn" {
  description = "ARN of the SQS queue for the crawler tasks"
  type        = string
}

variable "rds_db_resource_id" {
  description = "Resource ID of the RDS DB instance for IAM auth"
  type        = string
}

resource "aws_iam_role" "furniture_crawler_task_role" {
  name = "${var.project}-crawler-task-role-${data.aws_region.current.region}"

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
    Name    = "${var.project}-crawler-task-role-${data.aws_region.current.region}"
  }
}

resource "aws_iam_role_policy" "s3_write_policy" {
  name = "${var.project}-crawler-s3-write"
  role = aws_iam_role.furniture_crawler_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3WriteReadList"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "sqs_crawler_receive_policy" {
  name = "${var.project}-crawler-sqs-receive"
  role = aws_iam_role.furniture_crawler_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSReceive"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
        ]
        Resource = var.crawler_sqs_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_iam_connect_policy" {
  name = "${var.project}-crawler-rds-iam-connect"
  role = aws_iam_role.furniture_crawler_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSIAMConnectForCrawlerUser"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:${var.shared_services_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_db_resource_id}/${var.crawler_db_username}"
      }
    ]
  })
}

output "furniture_crawler_task_role_arn" {
  value       = aws_iam_role.furniture_crawler_task_role.arn
  description = "ARN of the ECS task role with S3 write permissions"
}
