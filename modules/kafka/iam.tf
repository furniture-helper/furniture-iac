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
}

resource "aws_iam_role_policy_attachment" "kafka_ssm" {
  role       = aws_iam_role.kafka_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "kafka_ebs_attach" {
  name = "${var.project}-kafka-ebs-attach"
  role = aws_iam_role.kafka_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AssociateAddress",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kafka_profile" {
  name = "${var.project}-kafka-profile"
  role = aws_iam_role.kafka_ssm_role.name
}
