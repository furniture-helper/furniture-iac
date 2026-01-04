variable "project" {
  type = string
}
variable "region" {
  type = string
}
variable "github_organization" {
  type = string
}
variable "ecr_repository_name" {
  type = string
}

variable "crawler_s3_bucker_arn" {
  type = string
}

variable "furniture_crawler_task_definition_arn" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}
