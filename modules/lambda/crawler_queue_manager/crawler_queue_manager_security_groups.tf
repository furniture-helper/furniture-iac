variable "vpc_id" {
  description = "VPC ID where the Lambda function will run"
  type        = string
}

variable "rds_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}

resource "aws_security_group" "crawler_queue_manager_lambda_sg" {
  name        = "crawler-queue-manager-lambda-sg"
  description = "Security group for the Crawler Queue Manager Lambda function"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "crawler_queue_manager_lambda_https_egress" {
  security_group_id = aws_security_group.crawler_queue_manager_lambda_sg.id
  description       = "Allow outbound HTTPS traffic"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "crawler_queue_manager_allow_rds_egress" {
  security_group_id        = aws_security_group.crawler_queue_manager_lambda_sg.id
  description              = "Allow outbound Postgres traffic to RDS"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.rds_sg_id
}

output "crawler_queue_manager_lambda_sg_id" {
  description = "Security group ID for the Crawler Queue Manager Lambda function"
  value       = aws_security_group.crawler_queue_manager_lambda_sg.id
}
