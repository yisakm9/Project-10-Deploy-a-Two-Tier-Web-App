output "security_group_id" {
  description = "The ID of the security group attached to the EIC Endpoint."
  value       = aws_security_group.eic_endpoint.id
}