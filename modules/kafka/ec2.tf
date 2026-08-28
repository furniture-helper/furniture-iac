variable "subnet_id" {
  description = "The subnet ID where the EC2 instance will be launched"
  type        = string
}

data "aws_ami" "amazon_linux_2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_launch_template" "kafka_server" {
  name_prefix   = "${var.project}-kafka-"
  image_id      = data.aws_ami.amazon_linux_2023_arm64.id
  instance_type = "t4g.medium"
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    docker_compose_content          = file("${path.module}/docker-compose.yml")
    database_credentials_secret_arn = var.database_credentials_secret_arn
    rds_db_endpoint                 = var.rds_db_endpoint
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.kafka_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.kafka_sg.id]
  }
  metadata_options {
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  tags = {
    Name    = "${var.project}-kafka-server"
    Project = var.project
  }
}

resource "aws_autoscaling_group" "kafka_server" {
  name                = "${var.project}-kafka-asg"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = [var.subnet_id]
  health_check_type   = "EC2"
  capacity_rebalance  = true

  launch_template {
    id      = aws_launch_template.kafka_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-kafka-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }
}

resource "aws_eip" "kafka_server" {
  domain = "vpc"

  tags = {
    Name    = "${var.project}-kafka-eip"
    Project = var.project
  }
}

data "aws_instances" "kafka_server" {
  instance_tags = {
    Name    = "${var.project}-kafka-server"
    Project = var.project
  }

  instance_state_names = ["pending", "running"]

  depends_on = [aws_autoscaling_group.kafka_server]
}

resource "aws_eip_association" "kafka_server" {
  instance_id   = data.aws_instances.kafka_server.ids[0]
  allocation_id = aws_eip.kafka_server.id
}

output "kafka_server_public_ip" {
  value = aws_eip.kafka_server.public_ip
}
