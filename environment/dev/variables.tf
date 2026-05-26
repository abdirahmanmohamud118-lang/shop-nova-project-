###########################################
# global variables
###########################################

variable "project_name" {
  description = "Name of the project — used to tag and name all resources"
  type        = string
  default     = "shopnova"
}

variable "environment" {
  description = "Deployment environment — controls sizing and behaviour"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging or prod"
  }
}

variable "aws_region" {
  description = "AWS region to deploy ShopNova into"
  type        = string
  default     = "us-east-1"
}

###########################################
# networking variables
###########################################

variable "vpc_cidr" {
  description = "IP address range for the entire VPC — all subnets are carved from this automatically"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret storing the RDS password"
  type        = string
  default     = "null"
}



###########################################
# cloudfront variables
###########################################

variable "cloudfront_price_class" {
  description = "Which edge locations CloudFront uses"
  type        = string
  default     = "PriceClass_100"
}


###########################################
# compute variables
###########################################


variable "web_server_config" {
  description = "EC2 Auto Scaling Group configuration"
  type = object({
    instance_type    = string
    key_name         = string
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    instance_type    = "t2.micro"
    key_name         = ""
    min_size         = 1
    max_size         = 1
    desired_capacity = 1
  }
}

variable "order_processing_config" {
  description = "EC2 Auto Scaling Group configuration"
  type = object({
    instance_type    = string
    key_name         = string
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    instance_type    = "t2.micro"
    key_name         = ""
    min_size         = 1
    max_size         = 1
    desired_capacity = 1
  }
}

###########################################
# database variables
###########################################


variable "database_config" {
  description = "RDS database configuration"
  type = object({
    instance_class          = string
    db_name                 = string
    db_username             = string
    multi_az                = bool
    backup_retention_period = number
    allocated_storage       = number
  })
  default = {
    instance_class          = "db.t3.micro"
    db_name                 = "shopnova_db"
    db_username             = "db_admin"
    multi_az                = false
    backup_retention_period = 0
    allocated_storage       = 20
  }
}
