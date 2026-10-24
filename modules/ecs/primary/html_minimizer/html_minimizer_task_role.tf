variable "project" {
  description = "Project name"
  type        = string
}

variable "minimized_html_s3_bucket_arn" {
  description = "ARN of the S3 bucket for the html minimizer"
  type        = string
}

variable "raw_html_s3_bucket_arn" {
  description = "ARN of the S3 bucket for the raw HTML storage"
  type        = string
}

variable "anchor_tree_s3_bucket_arn" {
  description = "ARN of the S3 bucket for boilerplate remover anchor tree"
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

variable "minimizer_db_username" {
  description = "Database username used by the HTML minimizer workload"
  type        = string
}

resource "aws_iam_role" "html_minimizer_task_role" {
  name = "${var.project}-html-minimizer-task-role"

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
    Name    = "${var.project}-html-minimizer-task-role"
  }
}

resource "aws_iam_role_policy" "s3_minimized_html_write_policy" {
  name = "${var.project}-html-minimizer-s3-write"
  role = aws_iam_role.html_minimizer_task_role.name

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
          var.minimized_html_s3_bucket_arn,
          "${var.minimized_html_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_raw_html_read_policy" {
  name = "${var.project}-raw-html-s3-read"
  role = aws_iam_role.html_minimizer_task_role.name

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
          var.raw_html_s3_bucket_arn,
          "${var.raw_html_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "anchor_tree_s3_read_policy" {
  name = "${var.project}-anchor-tree-s3-read"
  role = aws_iam_role.html_minimizer_task_role.name

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
          var.anchor_tree_s3_bucket_arn,
          "${var.anchor_tree_s3_bucket_arn}/anchor_tree/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_iam_connect_policy" {
  name = "${var.project}-html-minimizer-rds-iam-connect"
  role = aws_iam_role.html_minimizer_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSIAMConnectForMinimizerUser"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:${var.shared_services_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_db_resource_id}/${var.minimizer_db_username}"
      }
    ]
  })
}

output "html_minimizer_task_role_arn" {
  value       = aws_iam_role.html_minimizer_task_role.arn
  description = "ARN of the ECS task role for HTML minimizer"
}
