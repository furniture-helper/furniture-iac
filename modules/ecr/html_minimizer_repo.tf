resource "aws_ecr_repository" "html_minimizer_ecr_repo" {
  # checkov:skip=CKV_AWS_136: "Using default encryption is acceptable for this repo"
  # checkov:skip=CKV_AWS_51: "Images are immutable except for latest"

  name                 = "furniture-helper/html-minimizer"
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
    Name    = "${var.project}-html-minimizer-ecr"
    Project = var.project
  }
}

output "html-minimizer_ecr_repo_uri" {
  value       = aws_ecr_repository.html_minimizer_ecr_repo.repository_url
  description = "URL of the ECR repository for the furniture html minimizer"
}

output "html_minimizer_ecr_repo_arn" {
  value       = aws_ecr_repository.html_minimizer_ecr_repo.arn
  description = "ARN of the ECR repository for the furniture html minimizer"
}

resource "aws_ecr_lifecycle_policy" "html_minimizer_lifecycle" {
  repository = aws_ecr_repository.html_minimizer_ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the 'latest' tag, expire all other tagged images"
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
        description  = "Expire all untagged images (and any images that lost their 'latest' tag)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      }
    ]
  })
}
