# backend/modules/alb/outputs.tf

output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_security_group_id" {
  description = "The ID of the ALB's security group, needed by the EC2 module."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "The ARN of the target group, needed for instance attachments."
  value       = aws_lb_target_group.main.arn
}