variable "vpc_id" {
  description = "VPC ID where the ECS tasks will run"
  type        = string
}

resource "aws_security_group" "ecs_tasks_sg" {
  # checkov:skip=CKV2_AWS_5: "This security group is attached via the output to resources that require all outbound traffic"
  name        = "${var.project}-ecs-tasks-sg"
  description = "Allow all outbound HTTPS traffic for ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All outbound HTTPS traffic"
  }

  tags = {
    Name    = "${var.project}-ecs-tasks-sg"
    Project = var.project
  }
}

