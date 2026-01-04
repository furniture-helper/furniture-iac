resource "aws_iam_role" "furniture_crawler_task_role" {
  name = "${var.project}-crawler-task-role"

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
    Name    = "${var.project}-crawler-task-role"
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
          var.crawler_s3_bucket_arn,
          "${var.crawler_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

output "furniture_crawler_task_role_arn" {
  value       = aws_iam_role.furniture_crawler_task_role.arn
  description = "ARN of the ECS task role with S3 write permissions"
}
