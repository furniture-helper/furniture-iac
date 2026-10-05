variable "minimized_html_s3_bucket_arn" {
  description = "ARN of the minimized HTML S3 bucket"
  type        = string
}

resource "aws_iam_role" "information_extractor_task_role" {
  name = "${var.project}-information-extractor-task-role"

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
    Name    = "${var.project}-information-extractor-task-role"
  }
}

resource "aws_iam_role_policy" "minimized_html_s3_read_policy" {
  name = "${var.project}-information-extractor-s3-read"
  role = aws_iam_role.information_extractor_task_role.name

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
