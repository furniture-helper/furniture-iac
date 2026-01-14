variable "project" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "allow_public_connections" {
  type    = bool
  default = false
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.allow_public_connections ? var.public_subnet_ids : var.private_subnet_ids

  tags = {
    Name    = "${var.project}-db-subnet-group"
    Project = var.project
  }
}

resource "aws_rds_cluster" "db_cluster" {
  # checkov:skip=CKV_AWS_327: "Encryption using KMS not yet implemented"
  # checkov:skip=CKV2_AWS_8: "I don't know what AWS backups are"
  cluster_identifier                  = "${var.project}-rds-cluster"
  engine                              = "aurora-postgresql"
  engine_version                      = "17.4"
  database_name                       = local.db_creds.database_name
  master_username                     = local.db_creds.username
  master_password                     = local.db_creds.password
  db_subnet_group_name                = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids              = [aws_security_group.rds_sg.id]
  skip_final_snapshot                 = false
  apply_immediately                   = true
  deletion_protection                 = true
  iam_database_authentication_enabled = true
  copy_tags_to_snapshot               = true
  storage_encrypted                   = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.rds_parameter_group.name
  final_snapshot_identifier           = "${var.project}-rds-final-snapshot"

  lifecycle {
    prevent_destroy = true
  }

  serverlessv2_scaling_configuration {
    min_capacity             = 0
    max_capacity             = 1
    seconds_until_auto_pause = 60
  }

  tags = {
    Name    = "${var.project}-db-cluster"
    Project = var.project
  }
}

resource "aws_rds_cluster_instance" "db_instance" {
  # checkov:skip=CKV_AWS_354: "No need to encrypt performance insights yet"
  count                        = 1
  identifier                   = "${var.project}-rds-instance-${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.db_cluster.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.db_cluster.engine
  engine_version               = aws_rds_cluster.db_cluster.engine_version
  publicly_accessible          = var.allow_public_connections
  auto_minor_version_upgrade   = true
  monitoring_interval          = 5
  monitoring_role_arn          = aws_iam_role.rds_enhanced_monitoring.arn
  performance_insights_enabled = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "${var.project}-db-instance-${count.index + 1}"
    Project = var.project
  }
}

resource "aws_rds_cluster_parameter_group" "rds_parameter_group" {
  name        = "${var.project}-rds-cluster-pg"
  family      = "aurora-postgresql17"
  description = "RDS default cluster parameter group"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1"
  }

  parameter {
    name  = "idle_session_timeout"
    value = "60000"
  }

  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "60000"
  }

  parameter {
    name  = "statement_timeout"
    value = "120000"
  }

  tags = {
    Name    = "${var.project}-rds-cluster-pg"
    Project = var.project
  }
}

output "cluster_endpoint" {
  value = aws_rds_cluster.db_cluster.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.db_cluster.reader_endpoint
}

output "cluster_id" {
  value = aws_rds_cluster.db_cluster.id
}
