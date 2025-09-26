# Amazon DocumentDB (MongoDB-compatible) Configuration for Conservice SRE Tech Challenge

# DocumentDB Subnet Group
resource "aws_docdb_subnet_group" "main" {
  name       = "${local.name_prefix}-documentdb-subnet-group"
  subnet_ids = module.vpc.database_subnets

  tags = local.common_tags
}

# DocumentDB Parameter Group
resource "aws_docdb_cluster_parameter_group" "main" {
  family = "docdb4.0"
  name   = "${local.name_prefix}-documentdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }

  tags = local.common_tags
}

# DocumentDB Cluster
resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${local.name_prefix}-documentdb"
  engine                 = "docdb"
  engine_version         = "4.0.0"
  master_username        = "billingadmin"
  master_password        = random_password.documentdb_password.result
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot    = true
  deletion_protection    = false

  db_subnet_group_name   = aws_docdb_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.documentdb.id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name

  enabled_cloudwatch_logs_exports = [
    "audit"
  ]

  tags = local.common_tags
}

# DocumentDB Cluster Instances
resource "aws_docdb_cluster_instance" "main" {
  count              = var.documentdb_instance_count
  identifier         = "${local.name_prefix}-documentdb-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.documentdb_instance_class

  tags = local.common_tags
}

# Security Group for DocumentDB
resource "aws_security_group" "documentdb" {
  name_prefix = "${local.name_prefix}-documentdb-"
  description = "Security group for DocumentDB cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 27017 # DocumentDB default port
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_cluster.id, module.eks.node_security_group_id] # Allow access from EKS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Random password for DocumentDB
resource "random_password" "documentdb_password" {
  length  = 16
  special = true
}

# Store DocumentDB credentials in Secrets Manager
resource "aws_secretsmanager_secret" "documentdb_credentials" {
  name                    = "${local.name_prefix}-documentdb-credentials"
  description             = "DocumentDB credentials for billing service"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "documentdb_credentials" {
  secret_id = aws_secretsmanager_secret.documentdb_credentials.id
  secret_string = jsonencode({
    username = "billingadmin"
    password = random_password.documentdb_password.result
    endpoint = aws_docdb_cluster.main.endpoint
    port     = aws_docdb_cluster.main.port
  })
}
