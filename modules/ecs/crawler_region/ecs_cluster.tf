moved {
  from = aws_ecs_cluster.furniture_secondary_cluster
  to   = aws_ecs_cluster.furniture_cluster
}

moved {
  from = aws_ecs_cluster_capacity_providers.furniture_secondary_cluster_capacity_providers
  to   = aws_ecs_cluster_capacity_providers.furniture_cluster_capacity_providers
}

resource "aws_ecs_cluster" "furniture_cluster" {
  # checkov:skip=CKV_AWS_65: "Container insights is disabled to avoid additional costs."
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Project = var.project
    Name    = var.cluster_tag_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "furniture_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.furniture_cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
