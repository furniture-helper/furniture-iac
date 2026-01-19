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

resource "aws_db_instance" "db_instance" {
  identifier                          = "${var.project}-db-instance"
  engine                              = "postgres"
  engine_version                      = "17.4"
  instance_class                      = "db.t4g.micro"
  db_name                             = local.db_creds.database_name
  username                            = local.db_creds.username
  password                            = local.db_creds.password
  db_subnet_group_name                = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids              = [aws_security_group.rds_sg.id]
  allocated_storage                   = 20
  storage_type                        = "gp3"
  storage_encrypted                   = true
  backup_retention_period             = 7
  publicly_accessible                 = var.allow_public_connections
  monitoring_interval                 = 5
  monitoring_role_arn                 = aws_iam_role.rds_enhanced_monitoring.arn
  performance_insights_enabled        = true
  parameter_group_name                = aws_db_parameter_group.rds_parameter_group.name
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "${var.project}-rds-final-snapshot"
  apply_immediately                   = true
  iam_database_authentication_enabled = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "${var.project}-db-instance"
    Project = var.project
  }
}



resource "aws_db_parameter_group" "rds_parameter_group" {
  name        = "${var.project}-rds-pg"
  family      = "postgres17"
  description = "RDS default parameter group"

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
    Name    = "${var.project}-rds-pg"
    Project = var.project
  }
}

output "db_endpoint" {
  value = aws_db_instance.db_instance.address
}

output "db_instance_id" {
  value = aws_db_instance.db_instance.id
}
