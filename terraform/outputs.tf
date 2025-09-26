# Outputs for Conservice SRE Tech Challenge Infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

# EKS Outputs
output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.db_instance_name
}

# OpenSearch Outputs
output "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = module.opensearch.domain_endpoint
  sensitive   = true
}

# DocumentDB Outputs
output "documentdb_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
  sensitive   = true
}

output "documentdb_port" {
  description = "DocumentDB cluster port"
  value       = aws_docdb_cluster.main.port
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = { for repo in aws_ecr_repository.repos : repo.name => repo.repository_url }
}

# Load Balancer Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.lb_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.alb.lb_zone_id
}

# Kubernetes Config (temporarily disabled)
# output "kubeconfig" {
#   description = "Kubectl config file contents"
#   value       = module.eks.kubeconfig
#   sensitive   = true
# }

# Cost and Resource Summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    vpc_id                    = module.vpc.vpc_id
    cluster_name              = module.eks.cluster_id
    rds_endpoint              = module.rds.db_instance_endpoint
    documentdb_endpoint       = aws_docdb_cluster.main.endpoint
    opensearch_endpoint       = module.opensearch.domain_endpoint
    ecr_repositories          = [for repo in aws_ecr_repository.repos : repo.name]
    load_balancer_dns         = module.alb.lb_dns_name
  }
}
