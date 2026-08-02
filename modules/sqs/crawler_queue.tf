variable "project" {
  description = "The name of the project"
  type        = string
}

# ── Primary queue (consumed by the primary-region crawler) ──────────────────
resource "aws_sqs_queue" "crawler_queue" {
  # checkov:skip=CKV_AWS_27: "Encryption not required for this use case"
  name                       = "${var.project}-crawler-queue"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 3600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.crawler_secondary_queue.arn
    maxReceiveCount     = 1
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-queue"
  }
}

# ── Secondary queue (consumed by the secondary-region crawler) ───────────────
resource "aws_sqs_queue" "crawler_secondary_queue" {
  # checkov:skip=CKV_AWS_27: "Encryption not required for this use case"
  name                       = "${var.project}-crawler-secondary-queue"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 3600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.crawler_tertiary_queue.arn
    maxReceiveCount     = 1
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-secondary-queue"
  }
}

resource "aws_sqs_queue_policy" "crawler_secondary_queue_policy" {
  queue_url = aws_sqs_queue.crawler_secondary_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPrimaryQueueRedrive"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.crawler_secondary_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_sqs_queue.crawler_queue.arn
          }
        }
      }
    ]
  })
}

# ── Tertiary queue (consumed by the tertiary-region crawler) ─────────────────
resource "aws_sqs_queue" "crawler_tertiary_queue" {
  # checkov:skip=CKV_AWS_27: "Encryption not required for this use case"
  name                       = "${var.project}-crawler-tertiary-queue"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 3600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.crawler_dlq.arn
    maxReceiveCount     = 1
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-tertiary-queue"
  }
}

resource "aws_sqs_queue_policy" "crawler_tertiary_queue_policy" {
  queue_url = aws_sqs_queue.crawler_tertiary_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSecondaryQueueRedrive"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.crawler_tertiary_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_sqs_queue.crawler_secondary_queue.arn
          }
        }
      }
    ]
  })
}

# ── Dead-letter queue ─────────────────────────────────────────────────────────
resource "aws_sqs_queue" "crawler_dlq" {
  # checkov:skip=CKV_AWS_27: "Encryption not required for this use case"
  name                       = "${var.project}-crawler-dlq"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 43200

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-dlq"
  }
}

resource "aws_sqs_queue_policy" "crawler_dlq_policy" {
  queue_url = aws_sqs_queue.crawler_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowTertiaryQueueRedrive"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.crawler_dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_sqs_queue.crawler_tertiary_queue.arn
          }
        }
      }
    ]
  })
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "crawler_queue_arn" {
  description = "ARN of the primary crawler SQS queue"
  value       = aws_sqs_queue.crawler_queue.arn
}

output "crawler_queue_url" {
  description = "URL of the primary crawler SQS queue"
  value       = aws_sqs_queue.crawler_queue.url
}

output "crawler_secondary_queue_arn" {
  description = "ARN of the secondary crawler SQS queue"
  value       = aws_sqs_queue.crawler_secondary_queue.arn
}

output "crawler_secondary_queue_url" {
  description = "URL of the secondary crawler SQS queue"
  value       = aws_sqs_queue.crawler_secondary_queue.url
}

output "crawler_tertiary_queue_arn" {
  description = "ARN of the tertiary crawler SQS queue"
  value       = aws_sqs_queue.crawler_tertiary_queue.arn
}

output "crawler_tertiary_queue_url" {
  description = "URL of the tertiary crawler SQS queue"
  value       = aws_sqs_queue.crawler_tertiary_queue.url
}
