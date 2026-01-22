resource "aws_ecr_repository" "furniture_crawler_queue_manager_ecr_repo" {
  # checkov:skip=CKV_AWS_136: "Using default encryption is acceptable for this repo"
  # checkov:skip=CKV_AWS_51: "Images are immutable except for latest"

  name                 = "furniture-helper/furniture-crawler-queue-manager"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest"
    filter_type = "WILDCARD"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.project}-crawler-queue-manager-ecr"
    Project = var.project
  }
}

resource "aws_ecr_repository_policy" "lambda_ecr_policy" {
  repository = aws_ecr_repository.furniture_crawler_queue_manager_ecr_repo.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "LambdaECRImageRetrievalPolicy",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "furniture_crawler_queue_manager_lifecycle" {
  repository = aws_ecr_repository.furniture_crawler_queue_manager_ecr_repo.name

  policy = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep the most recent `latest` tag",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["latest"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
POLICY
}


output "furniture_crawler_queue_manager_ecr_repo_uri" {
  value       = aws_ecr_repository.furniture_crawler_queue_manager_ecr_repo.repository_url
  description = "URL of the ECR repository for the furniture crawler queue manager"
}

output "furniture_crawler_queue_manager_ecr_repo_arn" {
  value       = aws_ecr_repository.furniture_crawler_queue_manager_ecr_repo.arn
  description = "ARN of the ECR repository for the furniture crawler queue manager"
}
