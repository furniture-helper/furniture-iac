data "aws_subnet" "kafka_subnet" {
  id = var.subnet_id
}

resource "aws_ebs_volume" "kafka_data" {
  # checkov:skip=CKV_AWS_189: "Cannot afford encryption yet, will be implemented in the future"
  availability_zone = data.aws_subnet.kafka_subnet.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "${var.project}-kafka-data"
    Project = var.project
  }
}
