resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

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
  cidr_block              = "10.0.0.0/24"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-public-subnet-1"
    Project = var.project
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = false

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
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-private-subnet-1"
    Project = var.project
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
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
