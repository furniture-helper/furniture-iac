resource "aws_vpc" "vpc" {
  # checkov:skip=CKV2_AWS_11: "Cannot afford VPC flow logs."
  cidr_block                       = var.vpc_cidr_block
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name    = "${var.project}-vpc"
    Project = var.project
  }
}

resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-default-sg"
    Project = var.project
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[0]
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true

  tags = {
    Name    = "${var.project}-public-subnet-1"
    Project = var.project
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[1]
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = false

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, 2)
  assign_ipv6_address_on_creation = true

  tags = {
    Name    = "${var.project}-public-subnet-2"
    Project = var.project
  }

}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "${var.project}-public-rt"
    Project = var.project
  }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidr_blocks[0]
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-private-subnet-1"
    Project = var.project
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidr_blocks[1]
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-private-subnet-2"
    Project = var.project
  }
}

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
  ]
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
  ]
  description = "IDs of the private subnets"
}
