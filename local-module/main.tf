#############################
# security_group
#############################

resource "aws_security_group" "this" {
  vpc_id      = var.vpc_id
  name        = "${var.environment}-${var.name}-sg"
  description = "Security group for ${var.name} in ${var.environment}"

  tags = {
    Name        = "${var.environment}-${var.name}-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "cidr_ingress" {
  for_each = { 
    for rule in var.ingress_with_cidr_blocks : 
    rule["from_port"] => rule 
  }

  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value["cidr_block"]
  from_port         = each.value["from_port"]
  to_port           = each.value["to_port"]
  ip_protocol       = each.value["protocol"]
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress" {
  for_each = { 
    for rule in var.ingress_with_source_security_group_id : 
    rule["from_port"] => rule 
  }

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value["source_security_group_id"]
  from_port                    = each.value["from_port"]
  to_port                      = each.value["to_port"]
  ip_protocol                  = each.value["protocol"]
}

resource "aws_vpc_security_group_egress_rule" "cidr_egress" {
  for_each = { 
    for rule in var.egress_with_cidr_blocks : 
    rule["from_port"] => rule 
  }

  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value["cidr_block"]
  from_port         = each.value["from_port"]
  to_port           = each.value["to_port"]
  ip_protocol       = each.value["protocol"]
}


