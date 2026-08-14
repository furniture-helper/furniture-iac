resource "aws_security_group" "ecs_tasks_sg" {
  # checkov:skip=CKV2_AWS_5: "This security group is attached via the output to resources that require all outbound traffic"
  name        = "${var.project}-ecs-tasks-sg"
  description = "Allow all outbound HTTPS traffic for ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-ecs-tasks-sg"
    Project = var.project
  }
}

resource "aws_security_group_rule" "allow_https_outbound" {
  security_group_id = aws_security_group.ecs_tasks_sg.id
  description       = "Allow outbound HTTPS traffic"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "allow_5432_outbound_to_rds_sg" {
  count                    = var.rds_sg_id != null ? 1 : 0
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  description              = "Allow outbound Postgres traffic to RDS"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.rds_sg_id
}

resource "aws_security_group_rule" "allow_5432_outbound_to_rds_cidr" {
  count             = var.rds_sg_id == null ? 1 : 0
  security_group_id = aws_security_group.ecs_tasks_sg.id
  description       = "Allow outbound Postgres traffic to the public RDS endpoint"
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = var.rds_egress_cidr_blocks
}

resource "aws_security_group_rule" "allow_outbound_to_kafka" {
  security_group_id = aws_security_group.ecs_tasks_sg.id
  description       = "Allow outbound Kafka traffic to Kafka endpoint CIDRs"
  type              = "egress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks       = ["${var.kafka_public_ip}/32"]
}
