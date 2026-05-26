
###########################################
# autoscaling
###########################################
module "web-server-asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.2.1"


  name                      = "${var.project_name}-${var.environment}-asg"
  image_id                  = data.aws_ami.amazon_linux.id
  security_groups           = [module.web_server_sg.security_group_id]
  instance_type             = var.web_server_config.instance_type
  min_size                  = var.web_server_config.min_size
  max_size                  = var.web_server_config.max_size
  desired_capacity          = var.web_server_config.desired_capacity
  vpc_zone_identifier       = module.vpc.private_subnets
  iam_instance_profile_name = aws_iam_instance_profile.web_server.name
  traffic_source_attachments = {
    alb = {
      traffic_source_identifier = module.alb.target_groups["web_servers"].arn
      traffic_source_type       = "elbv2"
    }



    health_check_type         = "ELB"
    health_check_grace_period = 120
  }
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 20
        volume_type           = "gp3"
        delete_on_termination = true
      }
    }
  ]


  scaling_policies = {
    cpu_target_tracking = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120

      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 70.0
      }
    }
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -e

  # install dependencies
  yum update -y
  yum install -y nodejs npm aws-cli jq

  # fetch database credentials from Secrets Manager
  SECRET=$(aws secretsmanager get-secret-value \
    --secret-id ${aws_secretsmanager_secret.rds_secret.name} \
    --region ${var.aws_region} \
    --query SecretString \
    --output text)

  # export as environment variables for the application
  export DB_READ_HOST=$(echo $SECRET | jq -r '.read_host')
  export DB_WRITE_HOST=$(echo $SECRET | jq -r '.write_host')
  export DB_USER=$(echo $SECRET | jq -r '.username')
  export DB_PASS=$(echo $SECRET | jq -r '.password')
  export DB_NAME=$(echo $SECRET | jq -r '.database')
  export SQS_QUEUE_URL=${module.sqs.queue_url}
  export AWS_REGION=${var.aws_region}

  # start your web application
  # this would be replaced with your actual app startup command
  echo "Web server started" >> /var/log/shopnova.log
EOF
  )

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

}

###########################################
# autoscaling order processing 
###########################################
module "order-processing-asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.2.1"

  name                      = "${var.project_name}-${var.environment}-order-processing-asg"
  image_id                  = data.aws_ami.amazon_linux.id
  security_groups           = [module.order_processing_sg.security_group_id]
  instance_type             = var.order_processing_config.instance_type
  min_size                  = var.order_processing_config.min_size
  max_size                  = var.order_processing_config.max_size
  desired_capacity          = var.order_processing_config.desired_capacity
  vpc_zone_identifier       = module.vpc.private_subnets
  iam_instance_profile_name = aws_iam_instance_profile.order_processor.name


  scaling_policies = {
    queue_depth_tracking = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 60

      target_tracking_configuration = {
        customized_metric_specification = {
          metric_name = "ApproximateNumberOfMessagesVisible"
          namespace   = "AWS/SQS"
          statistic   = "Sum"

          dimensions = [{
            name  = "QueueName"
            value = module.sqs.queue_name
          }]
        }
        target_value = 100.0
      }
    }
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -e

  yum update -y
  yum install -y nodejs npm aws-cli jq

  SECRET=$(aws secretsmanager get-secret-value \
    --secret-id ${aws_secretsmanager_secret.rds_secret.name} \
    --region ${var.aws_region} \
    --query SecretString \
    --output text)

  export DB_WRITE_HOST=$(echo $SECRET | jq -r '.write_host')
  export DB_USER=$(echo $SECRET | jq -r '.username')
  export DB_PASS=$(echo $SECRET | jq -r '.password')
  export DB_NAME=$(echo $SECRET | jq -r '.database')
  export SQS_QUEUE_URL=${module.sqs.queue_url}
  export AWS_REGION=${var.aws_region}

  echo "Order processor started" >> /var/log/shopnova.log
EOF
  )



  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }


}



###########################################
# ALB
###########################################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name                       = "${var.project_name}-${var.environment}-alb"
  internal                   = false
  security_groups            = [module.alb_sg.security_group_id]
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  vpc_id                     = module.vpc.vpc_id

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }



    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
      forward = {
        target_group_key = "web_servers"
      }
    }
  }


  target_groups = {
    ex-instance = {
      name_prefix                       = "web"
      protocol                          = "HTTP"
      port                              = 8080
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_algorithm_type     = "round_robin"
      load_balancing_anomaly_mitigation = "on"
      load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
      health_check = {
        enabled             = true
        path                = "/health"
        port                = "8080"
        protocol            = "HTTP"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        matcher             = "200"
      }

      target_group_health = {
        dns_failover = {
          minimum_healthy_targets_count = 2
        }
        unhealthy_state_routing = {
          minimum_healthy_targets_percentage = 50
        }
      }
    }
  }



  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

}

##########################################################
# data for the project autoscaling group image 
##########################################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}