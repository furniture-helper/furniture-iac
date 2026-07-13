variable "project" {
  description = "Name prefix for resources"
  type        = string
  default     = "furniture"
}

variable "availability_zone_1" {
  description = "First Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
}

variable "availability_zone_2" {
  description = "Second Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for the two public subnets"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for the two private subnets"
  type        = list(string)
}
