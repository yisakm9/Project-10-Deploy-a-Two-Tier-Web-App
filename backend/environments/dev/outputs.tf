# backend/environments/dev/outputs.tf

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "app_subnet_ids" {
  description = "The IDs of the private application subnets."
  value       = module.vpc.app_subnet_ids
}

output "data_subnet_ids" {
  description = "The IDs of the private data subnets."
  value       = module.vpc.data_subnet_ids
}


output "application_url" {
  description = "The public URL of the application load balancer."
  value       = "http://${module.alb.alb_dns_name}"
}