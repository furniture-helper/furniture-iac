variable "project" {
  description = "Name prefix for resources"
  type        = string
  default     = "furniture"
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "availability_zone" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
  default     = "eu-west-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "github_organization" {
  type    = string
  default = "furniture-helper"
}
