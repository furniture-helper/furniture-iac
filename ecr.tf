resource "aws_ecr_repository" "furniture_crawler_ecr_repo" {
  name                 = "${var.ecr_repository_name}/furniture-crawler"
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
