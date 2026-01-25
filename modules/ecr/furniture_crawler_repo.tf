variable "project" {
  type = string
}

resource "aws_ecr_repository" "furniture_crawler_ecr_repo" {
  # checkov:skip=CKV_AWS_136: "Using default encryption is acceptable for this repo"
  # checkov:skip=CKV_AWS_51: "Images are immutable except for latest"

  name                 = "furniture-helper/furniture-crawler"
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
    Name    = "${var.project}-crawler-ecr"
    Project = var.project
  }
}

output "furniture_crawler_ecr_repo_uri" {
  value       = aws_ecr_repository.furniture_crawler_ecr_repo.repository_url
  description = "URL of the ECR repository for the furniture crawler"
}

output "furniture_crawler_ecr_repo_arn" {
  value       = aws_ecr_repository.furniture_crawler_ecr_repo.arn
  description = "ARN of the ECR repository for the furniture crawler"
}

resource "aws_ecr_lifecycle_policy" "furniture_crawler_lifecycle" {
  repository = aws_ecr_repository.furniture_crawler_ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the most recent `latest` tag"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire all other tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = 0
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 3
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      }
    ]
  })
}
