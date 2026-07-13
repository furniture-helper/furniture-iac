output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.furniture_cluster.arn
  description = "ARN of the ECS cluster"
}

output "task_execution_role_arn" {
  value       = aws_iam_role.ecs_task_execution_role.arn
  description = "ARN of the ECS task execution role"
}

output "events_invoke_ecs_role_arn" {
  value       = aws_iam_role.events_invoke_ecs_role.arn
  description = "ARN of the IAM role that allows EventBridge to invoke ECS tasks"
}

output "ecs_tasks_sg_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks_sg.id
}
