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
