# variable "family" {
#   description = "Task definition family/name"
#   type        = string
#   default     = "furniture-crawler"
# }
#
# variable "container_name" {
#   description = "Name of the container"
#   type        = string
#   default     = "furniture-crawler"
# }
#
# variable "container_image" {
#   description = "Container image URI"
#   type        = string
# }
#
# variable "container_cpu" {
#   description = "Container CPU units"
#   type        = number
#   default     = 256
# }
#
# variable "container_memory" {
#   description = "Container memory (MiB)"
#   type        = number
#   default     = 512
# }
#
# variable "port_mappings" {
#   description = "List of port mappings for container (map objects)"
#   type = list(object({
#     containerPort = number
#     hostPort      = number
#     protocol      = string
#   }))
#   default = []
# }
#
# variable "log_group_name" {
#   description = "CloudWatch Log Group name for awslogs driver"
#   type        = string
#   default     = "/aws/ecs/furniture-crawler"
# }
#
# variable "log_stream_prefix" {
#   description = "CloudWatch Logs stream prefix"
#   type        = string
#   default     = "ecs"
# }
#
# variable "network_mode" {
#   description = "Network mode for task definition"
#   type        = string
#   default     = "awsvpc"
# }
#
# variable "requires_compatibilities" {
#   description = "Compatibility list (FARGATE, EC2)"
#   type        = list(string)
#   default     = ["FARGATE"]
# }
#
# variable "task_cpu" {
#   description = "Task-level CPU"
#   type        = string
#   default     = "512"
# }
#
# variable "task_memory" {
#   description = "Task-level memory"
#   type        = string
#   default     = "1024"
# }
#
# variable "execution_role_arn" {
#   description = "Optional execution role ARN"
#   type        = string
#   default     = ""
# }
#
# variable "task_role_arn" {
#   description = "Optional task role ARN"
#   type        = string
#   default     = ""
# }
#
# variable "tags" {
#   description = "Tags to apply to the task definition"
#   type        = map(string)
#   default     = {}
# }

variable "project" {
  description = "Project name"
  type        = string
}

variable "furniture_crawler_ecr_repo_url" {
  description = "ECR repository URL for the furniture crawler"
  type        = string
}

variable "furniture_crawler_image_tag" {
  description = "Image tag for the furniture crawler container"
  type        = string
  default     = "latest"
}

variable "events_invoke_ecs_role_arn" {
  description = "ARN of the IAM role that allows EventBridge to invoke ECS tasks"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "furniture_crawler_task_role_arn" {
  description = "ARN of the furniture crawler ECS task role"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS tasks"
  type        = list(string)
}

variable "allow_all_egress_sg_id" {
  description = "Security group ID that allows all egress traffic"
  type        = string
}

variable "crawler_s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used by the furniture crawler"
}
