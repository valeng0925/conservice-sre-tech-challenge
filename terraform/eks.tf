# EKS Cluster Configuration for Conservice SRE Tech Challenge

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    main = {
      name = "billing-node-group"

      instance_types = var.node_group_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      # Launch template configuration
      launch_template = {
        name_prefix   = "${local.name_prefix}-"
        instance_type = "t3.small"
        vpc_security_group_ids = [aws_security_group.eks_cluster.id]

        # Enable detailed monitoring
        monitoring = {
          enabled = true
        }

        # User data for node initialization
        user_data = base64encode(file("${path.module}/user_data.sh"))
      }

      # Node group configuration
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      # Taints for workload isolation (optional)
      taints = []

      # Update configuration
      update_config = {
        max_unavailable_percentage = 50
      }
    }
  }

  # Cluster access configuration
  # Note: cluster_access_entries is not supported in this EKS module version
  # Access is managed through kubectl and IAM roles

  # Enable EKS Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # aws-ebs-csi-driver = {
    #   most_recent = true
    # }
  }

  # CloudWatch logging
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Tags
  tags = local.common_tags
}

