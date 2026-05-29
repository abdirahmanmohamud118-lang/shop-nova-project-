###########################################
# fetch available AZs dynamically
###########################################

data "aws_availability_zones" "available" {
  state = "available"
}

###########################################
# limit to 2 AZs our project need 2 azs 
###########################################

locals {
  active_azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

###########################################
# VPC
###########################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr
  azs  = local.active_azs

  private_subnets = [
    for i, az in local.active_azs :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]

  public_subnets = [
    for i, az in local.active_azs :
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  database_subnets = [
    for i, az in local.active_azs :
    cidrsubnet(var.vpc_cidr, 8, i + 20)
  ]

  create_igw             = true
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  create_database_subnet_group = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_route53_zone" "shopnova" {
  name = "shopnova.com"

  tags = {
    name        = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}


resource "aws_acm_certificate" "cert" {
  domain_name       = "shopnova.com"
  validation_method = "DNS"
  provider          = aws.virginia

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.shopnova.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}


/*
explanation >>>  when you request a cert in aws it return few things 
[
  {
    "domain_name": "shopnova.com",
    "resource_record_name": "_x2.shopnova.com",
    "resource_record_type": "CNAME",
    "resource_record_value": "_y3.acm-validations.aws"
  }
]
then the question becomes how do we use the key and the value 
we dont want to hardcode the name and the value because they are generated dynamically by aws
so we use for_each to loop through the list and create a record for each item in the list BEACUSE 
 you can have multiple domain names in a cert and each domain name will have its own validation record
*/


resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


resource "aws_route53_record" "cloudfront" {
  zone_id = aws_route53_zone.shopnova.zone_id
  name    = "shopnova.com"
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_distribution_domain_name
    zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}


