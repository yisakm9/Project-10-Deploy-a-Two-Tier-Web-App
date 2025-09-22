# backend/modules/iam/outputs.tf

output "instance_profile_name" {
  description = "The name of the IAM instance profile to attach to EC2 instances."
  value       = aws_iam_instance_profile.ec2_profile.name
}