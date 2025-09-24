# backend/environments/dev/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "me-central-1" 
}

variable "project_name" {
  description = "The name of the project, used for naming and tagging resources."
  type        = string
  default     = "two-tier-app"
}

# --- Add Database Credentials ---

variable "db_name" {
  description = "The name for the RDS database."
  type        = string
  default     = "tododb"
}

variable "db_username" {
  description = "The master username for the RDS database."
  type        = string
  default     = "masteruser"
}

