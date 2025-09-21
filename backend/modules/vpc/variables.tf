# backend/modules/vpc/variables.tf

variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "A list of Availability Zones to deploy into."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for the public subnets."
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Please provide exactly two public subnet CIDR blocks."
  }
}

variable "app_subnet_cidrs" {
  description = "A list of CIDR blocks for the private application subnets."
  type        = list(string)
  validation {
    condition     = length(var.app_subnet_cidrs) == 2
    error_message = "Please provide exactly two private application subnet CIDR blocks."
  }
}

variable "data_subnet_cidrs" {
  description = "A list of CIDR blocks for the private data subnets."
  type        = list(string)
  validation {
    condition     = length(var.data_subnet_cidrs) == 2
    error_message = "Please provide exactly two private data subnet CIDR blocks."
  }
}