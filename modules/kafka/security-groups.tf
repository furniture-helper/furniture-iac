variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
}

resource "aws_security_group" "kafka_sg" {
  name        = "${var.project}-kafka-allow-traffic"
  description = "Allow SSH and Kafka inbound traffic"

  vpc_id = var.vpc_id

  tags = {
    Name    = "${var.project}-kafka-allow-traffic"
    Project = var.project
  }
}

resource "aws_vpc_security_group_egress_rule" "kafka_ssm" {
  security_group_id = aws_security_group.kafka_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTPS for SSM"

  tags = {
    Name    = "${var.project}-kafka-allow-ssm-egress"
    Project = var.project
  }
}

resource "aws_vpc_security_group_egress_rule" "temp_allow_5432" {
  security_group_id = aws_security_group.kafka_sg.id
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow PostgreSQL traffic"

  tags = {
    Name    = "${var.project}-kafka-allow-postgresql-egress"
    Project = var.project
  }
}

resource "aws_security_group_rule" "allow_kafka_ingress_from_internet" {
  security_group_id = aws_security_group.kafka_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  description       = "Allow Kafka traffic from the internet"
}

resource "aws_security_group_rule" "allow_http_ingress_from_internet" {
  # checkov:skip=CKV_AWS_260: "Required public internet access for reverse proxy"

  security_group_id = aws_security_group.kafka_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  description       = "Allow HTTP traffic for reverse proxy"
}

resource "aws_security_group_rule" "allow_https_ingress_from_internet" {
  # checkov:skip=CKV_AWS_260: "Required public internet access for reverse proxy"

  security_group_id = aws_security_group.kafka_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  description       = "Allow HTTPS traffic for reverse proxy"
}

resource "aws_security_group_rule" "allow_outbound_to_19092" {
  security_group_id = aws_security_group.kafka_sg.id
  type              = "egress"
  from_port         = 19092
  to_port           = 19092
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound traffic to Kafka on port 19092"
}

resource "aws_security_group_rule" "allow_outbound_to_9092" {
  security_group_id = aws_security_group.kafka_sg.id
  type              = "egress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound traffic to Kafka on port 9092"
}

output "kafka_sg_id" {
  value = aws_security_group.kafka_sg.id
}
