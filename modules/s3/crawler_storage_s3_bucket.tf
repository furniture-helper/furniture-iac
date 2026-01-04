resource "aws_s3_bucket" "crawler_storage" {
  bucket = "furniture-crawler-storage"

  lifecycle {
    prevent_destroy = true
  }

  force_destroy = false

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-storage-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "crawler_storage_block" {
  bucket = aws_s3_bucket.crawler_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "crawler_storage_versioning" {
  bucket = aws_s3_bucket.crawler_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

output "crawler_storage_s3_bucket_arn" {
  value       = aws_s3_bucket.crawler_storage.arn
  description = "ARN of the S3 bucket used for crawler storage"
}

output "crawler_storage_s3_bucket_name" {
  value       = aws_s3_bucket.crawler_storage.bucket
  description = "Name of the S3 bucket used for crawler storage"
}
