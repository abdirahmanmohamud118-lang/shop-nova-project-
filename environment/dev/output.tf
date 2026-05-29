output "cloudfront_url" {
  description = "The global CDN domain name for the Shopnova application."
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "rds_endpoint" {
  description = "The global CDN domain name for the Shopnova application."
  value       =module.master_db.db_instance_endpoint
}

output "alb_url" {
  description = "The direct public URL of the Application Load Balancer."
  value =  module.alb.dns_name
}


output "route53_nameservers" {
    description = "The  authoritative nameservers for the Route53 hosted zone."
    value       = aws_route53_zone.shopnova.name_servers
}

output "sqs_url" {
  description = "The URL of the SQS queue."
  value = module.sqs.queue_url
}
