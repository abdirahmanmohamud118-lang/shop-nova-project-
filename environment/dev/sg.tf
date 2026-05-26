

###########################################
# SECURITY GROUPS
###########################################

###########################################
# ALB SG
###########################################

module "alb_sg" {
  source      = "../../local-module"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  name        = "alb"
  enable_iam  = false

  ingress_with_cidr_blocks = [
    {
      from_port  = "80"
      to_port    = "80"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    },
    {
      from_port  = "443"
      to_port    = "443"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port  = "8080"
      to_port    = "8080"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    }
  ]
}

###########################################
#  web_server_SG
###########################################

module "web_server_sg" {
  source      = "../../local-module"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  name        = "web_server_ec2"
  enable_iam  = true
  secret_arn  = var.secret_arn

  depends_on = [module.alb_sg]

  ingress_with_source_security_group_id = [
    {
      from_port                = "8080"
      to_port                  = "8080"
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port  = "443"
      to_port    = "443"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    }

  ]
}


###########################################
# order_processing SG
###########################################

module "order_processing_sg" {
  source      = "../../local-module"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  name        = "order_processing_ec2"
  enable_iam  = true
  secret_arn  = var.secret_arn


  egress_with_cidr_blocks = [
    {
      from_port  = "443"
      to_port    = "443"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
    }

  ]
}


###########################################
# database SG
###########################################

module "rds_sg" {
  source      = "../../local-module"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  name        = "rds"
  enable_iam  = false

  depends_on = [module.web_server_sg, module.order_processing_sg]

  ingress_with_source_security_group_id = [
    {
      from_port                = "3306"
      to_port                  = "3306"
      protocol                 = "tcp"
      source_security_group_id = module.web_server_sg.security_group_id
    },
    {
      from_port                = "3306"
      to_port                  = "3306"
      protocol                 = "tcp"
      source_security_group_id = module.order_processing_sg.security_group_id
    }
  ]
}
###########################################
# SQS SG
###########################################

module "sqs_sg" {
  source      = "../../local-module"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  name        = "sqs"
  enable_iam  = false

  ingress_with_source_security_group_id = [
    {
      from_port                = "443"
      to_port                  = "443"
      protocol                 = "tcp"
      source_security_group_id = "vpc-endpoint-sg-id" # replace with actual VPC Endpoint SG ID
    },
    {

    }
  ]
}
###########################################
# vpc endpoint SG
###########################################


resource "aws_security_group" "vpc_endpoint_sg" {
  name   = "${var.project_name}-${var.environment}-endpoint-sg"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-endpoint-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_from_web" {
  security_group_id            = aws_security_group.vpc_endpoint_sg.id
  referenced_security_group_id = module.web_server_sg.security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_from_order" {
  security_group_id            = aws_security_group.vpc_endpoint_sg.id
  referenced_security_group_id = module.order_processing_sg.security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

