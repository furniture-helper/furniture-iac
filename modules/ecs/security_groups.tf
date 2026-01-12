variable "vpc_id" {
  description = "VPC ID where the ECS tasks will run"
  type        = string
}

variable "rds_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}

resource "aws_security_group" "ecs_tasks_sg" {
  # checkov:skip=CKV2_AWS_5: "This security group is attached via the output to resources that require all outbound traffic"
  name        = "${var.project}-ecs-tasks-sg"
  description = "Allow all outbound HTTPS traffic for ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    description      = "Allow outbound HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.project}-ecs-tasks-sg"
    Project = var.project
  }
}

resource "aws_security_group_rule" "allow_5432_outbound_to_rds" {
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.rds_sg_id
}

output "ecs_tasks_sg_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks_sg.id
}
