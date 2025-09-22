# backend/modules/alb/variables.tf

variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the ALB in."
  type        = string
}

variable "subnet_ids" {
  description = "A list of public subnet IDs for the ALB."
  type        = list(string)
}