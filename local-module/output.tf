output "security_group_id" {
  description = "ID of the security group created by this module"
  value       = aws_security_group.this.id
}

output "security_group_name" {
  description = "Name of the security group created by this module"
  value       = aws_security_group.this.name
}



