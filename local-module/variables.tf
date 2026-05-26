#############################
# security_group variables 
#############################



variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "environment" {
  description = "Deployment environment dev | staging | prod"
  type        = string
}

variable "ingress_with_cidr_blocks" {
  description = "Ingress rules using CIDR — used for ALB internet access"
  type        = list(map(string))
  default     = []
}

variable "ingress_with_source_security_group_id" {
  description = "Ingress rules using SG reference — used for EC2 and RDS"
  type        = list(map(string))
  default     = []
}

variable "egress_with_cidr_blocks" {
  description = "Egress rules using CIDR — used for EC2 outbound"
  type        = list(map(string))
  default     = []
}
#####################################
# IAM ROLES && POLICIES variables
#####################################



variable "enable_iam" {
  description = "Set to true only for EC2 module call"
  type        = bool
  default     = false
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret EC2 can read"
  type        = string
  default     = null
}