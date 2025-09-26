# 🏗️ Terraform Infrastructure - Conservice SRE Tech Challenge

This directory contains Terraform configurations for provisioning AWS infrastructure for the Conservice billing microservice.

## 📋 Infrastructure Components

### Core Services
- **EKS Cluster** - Kubernetes orchestration with managed node groups
- **RDS PostgreSQL** - Managed database with Multi-AZ deployment
- **Amazon OpenSearch** - Search and analytics engine
- **ECR Repositories** - Container image storage
- **Application Load Balancer** - Traffic distribution and SSL termination

### Networking
- **VPC** - Isolated network environment
- **Public/Private Subnets** - Multi-AZ deployment
- **Database Subnets** - Isolated database tier
- **Security Groups** - Network access control
- **NAT Gateways** - Outbound internet access for private subnets

### Monitoring & Security
- **CloudWatch Logs** - Centralized logging
- **Secrets Manager** - Secure credential storage
- **IAM Roles** - Least privilege access
- **Encryption** - Data encryption at rest and in transit

## 🚀 Quick Start

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for Kubernetes management
- [Helm](https://helm.sh/docs/intro/install/) for package management

### 1. Configure Variables
```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the variables file with your values
nano terraform.tfvars
```

### 2. Initialize Terraform
```bash
cd terraform
terraform init
```

### 3. Plan the Infrastructure
```bash
terraform plan
```

### 4. Apply the Configuration
```bash
terraform apply
```

### 5. Configure kubectl
```bash
# Get the EKS cluster kubeconfig
aws eks update-kubeconfig --region us-west-2 --name conservice-billing-cluster

# Verify cluster access
kubectl get nodes
```

## 📁 File Structure

```
terraform/
├── main.tf                 # Main configuration and providers
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── versions.tf            # Terraform and provider versions
├── vpc.tf                 # VPC and networking
├── eks.tf                 # EKS cluster configuration
├── rds.tf                 # RDS PostgreSQL setup
├── opensearch.tf          # OpenSearch configuration
├── ecr.tf                 # ECR repositories
├── alb.tf                 # Application Load Balancer
├── user_data.sh           # EKS node initialization script
├── terraform.tfvars.example # Example variables
└── README.md              # This file
```

## 🔧 Configuration Details

### EKS Cluster
- **Version**: 1.28
- **Node Groups**: Managed node groups with auto-scaling
- **Add-ons**: CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- **Logging**: API, audit, authenticator, controller, scheduler logs

### RDS PostgreSQL
- **Engine**: PostgreSQL 15.4
- **Instance**: db.t3.micro (configurable)
- **Storage**: GP3 with auto-scaling
- **Backup**: 7-day retention
- **Security**: VPC isolation, encryption at rest

### OpenSearch
- **Version**: OpenSearch 2.11
- **Instance**: t3.small.search (configurable)
- **Security**: VPC endpoints, encryption, access policies
- **Logging**: Index, search, and application logs

### ECR Repositories
- **Repositories**: billing-backend, billing-frontend
- **Security**: Image scanning, lifecycle policies
- **Access**: IAM-based authentication

## 💰 Cost Optimization

### Development Environment
- **EKS**: t3.medium nodes (2-4 instances)
- **RDS**: db.t3.micro with 20GB storage
- **OpenSearch**: t3.small.search (1 instance)
- **ALB**: Standard load balancer

### Production Considerations
- Enable deletion protection for RDS
- Use larger instance types for production workloads
- Configure auto-scaling policies
- Set up monitoring and alerting

## 🔒 Security Features

### Network Security
- VPC with public/private subnet isolation
- Security groups with least privilege access
- Database subnets for additional isolation
- NAT gateways for private subnet internet access

### Data Security
- Encryption at rest for RDS and OpenSearch
- Encryption in transit with TLS
- Secrets Manager for credential storage
- IAM roles with minimal permissions

### Access Control
- EKS cluster access via IAM
- ECR repository policies
- OpenSearch access policies
- ALB security groups

## 📊 Monitoring & Observability

### CloudWatch Integration
- EKS cluster logs
- RDS performance insights
- OpenSearch application logs
- ALB access logs

### Cost Management
- Resource tagging for cost allocation
- S3 lifecycle policies for log retention
- ECR lifecycle policies for image cleanup

## 🚨 Important Notes

### State Management
- Configure S3 backend for remote state storage
- Use DynamoDB for state locking
- Never commit state files to version control

### Resource Limits
- Check AWS service limits before deployment
- Monitor costs during development
- Use appropriate instance types for your workload

### Security Considerations
- Review security group rules
- Validate IAM policies
- Test access controls
- Monitor for security events

## 🔄 Next Steps

After infrastructure deployment:

1. **Push Docker Images** to ECR repositories
2. **Deploy Applications** using Kubernetes manifests
3. **Configure Monitoring** with Datadog or CloudWatch
4. **Set up CI/CD** with GitHub Actions
5. **Implement Observability** with logging and metrics

## 📞 Support

For issues or questions:
- Check Terraform documentation
- Review AWS service documentation
- Consult the main project README
- Check GitHub issues for common problems

## 🏷️ Tags

All resources are tagged with:
- `Project`: conservice-billing
- `Environment`: dev/staging/prod
- `Owner`: SRE-Team
- `ManagedBy`: Terraform
- `CostCenter`: Engineering
