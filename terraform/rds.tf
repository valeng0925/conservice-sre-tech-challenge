# RDS PostgreSQL Configuration for Conservice SRE Tech Challenge

module "rds" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.name_prefix}-postgres"

  # Engine configuration
  engine               = "postgres"
  engine_version       = "13.22"
  family              = "postgres13"
  major_engine_version = "13"
  instance_class      = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted      = true

  # Database configuration
  db_name  = "billingdb"
  username = "billingadmin"
  password = random_password.db_password.result
  port     = "5432"
  
  # Enable RDS-managed master user password
  manage_master_user_password = true

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  subnet_ids             = module.vpc.database_subnets

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  delete_automated_backups = false

  # Monitoring and logging
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Deletion protection
  deletion_protection = false  # Set to true for production
  skip_final_snapshot = true  # Set to false for production

  # Multi-AZ for high availability
  multi_az = true

  # Parameter group
  create_db_parameter_group = true
  parameter_group_name      = "${local.name_prefix}-postgres-params"

  # Option group
  create_db_option_group = false

  # Tags
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres"
    Type = "Database"
  })

  # DB instance tags
  db_instance_tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgres-instance"
  })

  # DB option group tags
  db_option_group_tags = local.common_tags

  # DB parameter group tags
  db_parameter_group_tags = local.common_tags

  # DB subnet group tags
  db_subnet_group_tags = local.common_tags
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS automatically manages secrets when manage_master_user_password is true
# No need to create custom secrets


# RDS Proxy for connection pooling (optional but recommended)
resource "aws_db_proxy" "rds_proxy" {
  name                   = "${local.name_prefix}-rds-proxy"
  engine_family          = "POSTGRESQL"
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:rds!db-${module.rds.db_instance_identifier}"
  }
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = module.vpc.private_subnets
  require_tls           = true
  idle_client_timeout   = 1800

  tags = local.common_tags
}

resource "aws_db_proxy_default_target_group" "rds_proxy" {
  db_proxy_name = aws_db_proxy.rds_proxy.name
}

resource "aws_db_proxy_target" "rds_proxy" {
  db_proxy_name         = aws_db_proxy.rds_proxy.name
  target_group_name     = aws_db_proxy_default_target_group.rds_proxy.name
  db_instance_identifier = module.rds.db_instance_identifier
}

