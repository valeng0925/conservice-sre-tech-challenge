# Application Load Balancer for Conservice SRE Tech Challenge

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${local.name_prefix}-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.alb.id]

  # Access logs (commented out due to provider bug)
  # access_logs = {
  #   bucket = aws_s3_bucket.alb_logs.id
  #   prefix = "alb-logs"
  # }

  # Target groups
  target_groups = [
    {
      name             = "billing-backend-tg"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      tags = local.common_tags
    },
    {
      name             = "billing-frontend-tg"
      backend_protocol = "HTTP"
      backend_port     = 3001
      target_type      = "ip"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      tags = local.common_tags
    }
  ]

  # HTTP listeners
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 1  # Frontend target group
      action_type        = "forward"
    }
  ]

  # HTTPS listeners (commented out - requires valid domain and certificate)
  # https_listeners = [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = aws_acm_certificate.alb.arn
  #     target_group_index = 1  # Frontend target group
  #     action_type        = "forward"
  #   }
  # ]

  # Listener rules for API routing

  # Additional listener rules
  http_tcp_listener_rules = [
    {
      http_tcp_listener_index = 0
      priority                = 100
      actions = [
        {
          type               = "forward"
          target_group_index = 0  # Backend target group
        }
      ]
      conditions = [
        {
          path_patterns = ["/api/*", "/health", "/billing"]
        }
      ]
    }
  ]

  tags = local.common_tags
}

# Security group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${local.name_prefix}-alb-logs-${random_string.bucket_suffix.result}"

  tags = local.common_tags
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

# SSL Certificate for HTTPS
resource "aws_acm_certificate" "alb" {
  domain_name       = "*.${var.environment}.${var.project_name}.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

# Certificate validation (simplified - in production, you'd use Route53)
# Certificate validation (commented out - requires Route53 setup)
# resource "aws_acm_certificate_validation" "alb" {
#   certificate_arn         = aws_acm_certificate.alb.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

# Route53 record for certificate validation (commented out - requires existing hosted zone)
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }

# Route53 zone (commented out - you'd use your own domain)
# data "aws_route53_zone" "main" {
#   name         = "${var.environment}.${var.project_name}.com"
#   private_zone = false
# }
