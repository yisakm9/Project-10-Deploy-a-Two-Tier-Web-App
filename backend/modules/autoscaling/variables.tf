# backend/modules/autoscaling/variables.tf

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "launch_template_id" {
  description = "The ID of the EC2 Launch Template to use."
  type        = string
}

variable "vpc_zone_identifier" {
  description = "A list of subnet IDs the ASG can launch instances into."
  type        = list(string)
}

variable "target_group_arns" {
  description = "A list of ALB Target Group ARNs to attach instances to."
  type        = list(string)
}