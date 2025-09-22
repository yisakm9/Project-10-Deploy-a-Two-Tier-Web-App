# backend/modules/autoscaling/outputs.tf

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group."
  value       = aws_autoscaling_group.main.name
}