variable "vpc_id" {
  description = "VPC ID where the ECS tasks will run"
  type        = string
}

variable "ecs_tasks_sg_id" {
  description = "Security group for ECS tasks"
  type        = string
}

resource "aws_security_group" "rds_sg" {
  # checkov:skip=CKV2_AWS_5: "This security group is attached via the output to resources that require all outbound traffic"
  name        = "${var.project}-rds-sg"
  description = "Only allow inbound traffic from ECS tasks to RDS"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-rds-sg"
    Project = var.project
  }
}

resource "aws_security_group_rule" "allow_db_inbound_from_ecs_tasks" {
  security_group_id        = aws_security_group.rds_sg.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.ecs_tasks_sg_id
}

resource "aws_security_group_rule" "allow_all_inbound_on_5432" {
  count             = var.allow_public_connections ? 1 : 0
  security_group_id = aws_security_group.rds_sg.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds_sg.id
}
