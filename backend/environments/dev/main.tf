# backend/main.tf

# Data source to get the list of availability zones in the current region.
# This makes our configuration more resilient and adaptable to different regions.
data "aws_availability_zones" "available" {
  state = "available"
}

# Instantiate our custom VPC module
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"

  # We will use the first two available AZs for high availability.
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  app_subnet_cidrs = [
    "10.0.10.0/24",
    "10.0.20.0/24"
  ]

  data_subnet_cidrs = [
    "10.0.100.0/24",
    "10.0.200.0/24"
  ]
}

