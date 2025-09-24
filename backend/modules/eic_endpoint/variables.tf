variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to create the endpoint in."
  type        = string
}

variable "subnet_id" {
  description = "The ID of a single private subnet to place the endpoint in."
  type        = string
}