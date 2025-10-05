# Amazon OpenSearch Configuration for Conservice SRE Tech Challenge

module "opensearch" {
  source = "terraform-aws-modules/opensearch/aws"
  version = "~> 1.0"

  domain_name = "billing-opensearch"

  # Engine configuration
  engine_version = "OpenSearch_2.11"

  # Cluster configuration
  cluster_config = {
    instance_type            = var.opensearch_instance_type
    instance_count           = var.opensearch_instance_count
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
    multi_az_with_standby_enabled = false
  }

  # EBS configuration
  ebs_options = {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }

  # Network configuration
  vpc_options = {
    subnet_ids         = [module.vpc.private_subnets[0]]  # Use only the first subnet
    security_group_ids = [aws_security_group.opensearch.id]
  }

  # Access policy (simplified for VPC endpoint)
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/billing-opensearch/*"
      }
    ]
  })

  # Advanced security options
  advanced_security_options = {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options = {
      master_user_name     = "admin"
      master_user_password = random_password.opensearch_password.result
    }
  }

  # Auto-tune options (disabled for t3.small instances)
  auto_tune_options = {
    desired_state       = "DISABLED"
    rollback_on_disable = "NO_ROLLBACK"
    use_off_peak_window = false
  }

  # Log publishing (simplified)
  log_publishing_options = []

  # Tags
  tags = local.common_tags
}

# CloudWatch Log Groups for OpenSearch (simplified - not used)

# KMS Key for OpenSearch Logs Encryption
resource "aws_kms_key" "opensearch_logs" {
  description             = "KMS key for OpenSearch logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "opensearch_logs" {
  name          = "alias/${local.name_prefix}-opensearch-logs-key"
  target_key_id = aws_kms_key.opensearch_logs.key_id
}

# Store OpenSearch credentials in Secrets Manager
resource "aws_secretsmanager_secret" "opensearch_credentials" {
  name                    = "${local.name_prefix}-opensearch-credentials-v2"
  description             = "OpenSearch credentials for billing service"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "opensearch_credentials" {
  secret_id = aws_secretsmanager_secret.opensearch_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.opensearch_password.result
    endpoint = module.opensearch.domain_endpoint
  })
}

# Generate a strong password for OpenSearch master user
resource "random_password" "opensearch_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+"
}