# backend/modules/ec2/variables.tf

variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "The ID of the VPC to launch the instances in."
  type        = string
}

variable "subnet_ids" {
  description = "A list of private app subnet IDs to launch the instances in."
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile to attach to the instances."
  type        = string
}

variable "alb_security_group_id" {
  description = "The ID of the security group for the ALB, to allow inbound traffic."
  type        = string
}

# --- Database Credentials for Application ---
variable "db_endpoint" {
  description = "The endpoint of the RDS database."
  type        = string
}

variable "db_name" {
  description = "The name of the RDS database."
  type        = string
}

variable "db_username" {
  description = "The username for the RDS database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the RDS database."
  type        = string
  sensitive   = true
}