variable "project" {
  description = "The name of the project"
  type        = string
}

resource "aws_sqs_queue" "crawler_queue" {
  name                       = "${var.project}-crawler-queue"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 3600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 240

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.crawler_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Project = var.project
    Name    = "${var.project}-crawler-queue"
  }
}

resource "aws_sqs_queue" "crawler_dlq" {
  name                       = "${var.project}-crawler-dlq"
  delay_seconds              = 0
  max_message_size           = 2048
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 240

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
        Sid       = "AllowMainQueue"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.crawler_dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_sqs_queue.crawler_queue.arn
          }
        }
      }
    ]
  })
}

output "crawler_queue_arn" {
  description = "ARN of the crawler SQS queue"
  value       = aws_sqs_queue.crawler_queue.arn
}

output "crawler_queue_url" {
  description = "URL of the crawler SQS queue"
  value       = aws_sqs_queue.crawler_queue.url
}
