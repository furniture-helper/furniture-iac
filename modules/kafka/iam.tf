resource "aws_iam_role" "kafka_ssm_role" {
  name = "${var.project}-kafka-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name    = "${var.project}-kafka-ssm-role"
    Project = var.project
  }
}

resource "aws_iam_role_policy_attachment" "kafka_ssm" {
  role       = aws_iam_role.kafka_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "kafka_ebs_attach" {
  name = "${var.project}-kafka-ebs-attach"
  role = aws_iam_role.kafka_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AssociateAddress",
          "ec2:AttachVolume",
          "ec2:DetachVolume"
        ]
        Resource = [
          aws_ebs_volume.kafka_data.arn,
          aws_eip.kafka_server.arn,
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kafka_profile" {
  name = "${var.project}-kafka-profile"
  role = aws_iam_role.kafka_ssm_role.name

  tags = {
    Name    = "${var.project}-kafka-profile"
    Project = var.project
  }
}
