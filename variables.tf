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

variable "availability_zone_1" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
  default     = "eu-west-1a"
}

variable "availability_zone_2" {
  description = "Second Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
  default     = "eu-west-1b"
}

variable "github_organization" {
  type    = string
  default = "furniture-helper"
}
