variable "project" {
  description = "Name prefix for resources"
  type        = string
  default     = "furniture"
}

variable "availability_zone" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}
