# backend/modules/ec2/outputs.tf

output "ec2_security_group_id" {
  description = "The ID of the EC2 security group, for the RDS module to allow access."
  value       = aws_security_group.ec2.id
}

output "launch_template_id" {
  description = "The ID of the EC2 Launch Template, for the Auto Scaling module to use."
  value       = aws_launch_template.main.id
}