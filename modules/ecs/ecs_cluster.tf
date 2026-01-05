variable "project" {
  description = "Project name"
  type        = string
}

resource "aws_ecs_cluster" "furniture_cluster" {
  name = "${var.project}-cluster"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  tags = {
    Project = var.project
    Name    = "${var.project}-ecs-cluster"
  }
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.furniture_cluster.arn
  description = "ARN of the ECS cluster"
}
