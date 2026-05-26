
###########################################
# CLOUDFRONT
###########################################
module "cloudfront" {
  source     = "terraform-aws-modules/cloudfront/aws"
  version    = "3.2.1"
  depends_on = [aws_route53_zone.shopnova]

  aliases = ["shopnova.com"]

  viewer_certificate = {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  origin = {
    s3 = {
      domain_name              = aws_s3_bucket.static_content.bucket_regional_domain_name
      origin_id                = "s3"
      origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    }

    alb = {
      domain_name = module.alb.lb_dns_name
      origin_id   = "alb"

      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "alb"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values = {
      query_string = true
      headers      = ["*"]
      cookies = {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      # do not forward headers or cookies — static files
      # are the same for every user
      forwarded_values = {
        query_string = false
        cookies = {
          forward = "none"
        }
      }
    }
  ]

  price_class = var.cloudfront_price_class

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}







module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.1"

  name                        = "${var.project_name}-${var.environment}-order.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = "86400" # hii ni siku moja you can adjust as needed
  create_dlq                  = true
  redrive_policy = {
    maxReceiveCount = 3
  }
  visibility_timeout_seconds = 60



  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

}

###########################################
# SQS VPC endpoint
###########################################

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-sqs-endpoint"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}


###########################################
# Secrets Manager VPC endpoint
###########################################

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-secretsmanager-endpoint"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}