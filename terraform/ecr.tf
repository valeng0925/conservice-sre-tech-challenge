# ECR Repositories for Conservice SRE Tech Challenge

# Create ECR repositories for Docker images
resource "aws_ecr_repository" "repos" {
  for_each = toset(var.ecr_repositories)
  
  name                 = each.value
  image_tag_mutability   = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = each.value
    Type = "Container Registry"
  })
}

# ECR lifecycle policy for image cleanup
resource "aws_ecr_lifecycle_policy" "repos" {
  for_each = aws_ecr_repository.repos
  
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR repository policy for cross-account access (if needed)
resource "aws_ecr_repository_policy" "repos" {
  for_each = aws_ecr_repository.repos
  
  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      },
      {
        Sid    = "AllowEKSNodeGroup"
        Effect = "Allow"
        Principal = {
          AWS = module.eks.eks_managed_node_groups["main"].iam_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# ECR replication configuration (commented out - causes error when replicating to same region)
# resource "aws_ecr_replication_configuration" "repos" {
#   replication_configuration {
#     rule {
#       destination {
#         region      = var.aws_region
#         registry_id = data.aws_caller_identity.current.account_id
#       }
#     }
#   }
# }
