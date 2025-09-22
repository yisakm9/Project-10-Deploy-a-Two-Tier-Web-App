# backend/modules/rds/variables.tf

variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the RDS database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "The version of the MySQL engine to use."
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "The name of the initial database to be created."
  type        = string
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
  sensitive   = true # This is critical for security
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true # This is critical for security
}

variable "subnet_ids" {
  description = "A list of private data subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the RDS instance will be deployed."
  type        = string
}

variable "ec2_security_group_id" {
  description = "The ID of the security group for the EC2 instances, to allow DB access."
  type        = string
}