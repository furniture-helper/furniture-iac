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

variable "secondary_region" {
  description = "Secondary AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "tertiary_region" {
  description = "Tertiary AWS region to deploy into"
  type        = string
  default     = "us-east-1"
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

variable "secondary_availability_zone_1" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
  default     = "ap-southeast-1a"
}

variable "secondary_availability_zone_2" {
  description = "Second Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
  default     = "ap-southeast-1b"
}

variable "tertiary_availability_zone_1" {
  description = "Availability Zone to create subnets in (single-AZ setup)"
  type        = string
  default     = "us-east-1a"
}

variable "tertiary_availability_zone_2" {
  description = "Second Availability Zone to create subnets in (for multi-AZ setup)"
  type        = string
  default     = "us-east-1b"
}

variable "github_organization" {
  type    = string
  default = "furniture-helper"
}

variable "primary_crawler_schedule_expression" {
  description = "EventBridge schedule expression for the primary-region crawler task"
  type        = string
  default     = "cron(0/20 * * * ? *)"
}

variable "secondary_crawler_schedule_expression" {
  description = "EventBridge schedule expression for the secondary-region crawler task"
  type        = string
  default     = "rate(2 hour)"
}

variable "tertiary_crawler_schedule_expression" {
  description = "EventBridge schedule expression for the tertiary-region crawler task"
  type        = string
  default     = "rate(12 hours)"
}
