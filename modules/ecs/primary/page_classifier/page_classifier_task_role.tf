variable "minimized_html_s3_bucket_arn" {
  description = "ARN of the minimized HTML S3 bucket"
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

resource "aws_iam_role" "page_classifier_task_role" {
  name = "${var.project}-page-classifier-task-role"

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
    Name    = "${var.project}-page-classifier-task-role"
  }
}

resource "aws_iam_role_policy" "minimized_html_s3_read_policy" {
  name = "${var.project}-page-classifier-s3-read"
  role = aws_iam_role.page_classifier_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Read"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.minimized_html_s3_bucket_arn,
          "${var.minimized_html_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_iam_connect_policy" {
  name = "${var.project}-page-classifier-rds-iam-connect"
  role = aws_iam_role.page_classifier_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSIAMConnectForPageClassifierUser"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:${var.shared_services_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_db_resource_id}/${var.ecs_classifier_db_username}"
      }
    ]
  })
}
