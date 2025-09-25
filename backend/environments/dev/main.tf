# backend/environments/dev/main.tf

# Data  source to get the list of availability zones in the current region.
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_secretsmanager_secret" "db_password_secret" {
  name = "two-tier-app/rds/master-password"
}

data "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id = data.aws_secretsmanager_secret.db_password_secret.id
}

# The secret value is a JSON string, so we need to decode it
locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_password_version.secret_string)["password"]
}


# --- 1. Networking Layer ---
module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  app_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
  data_subnet_cidrs   = ["10.0.100.0/24", "10.0.200.0/24"]
}

# --- 2. Security & Permissions Layer ---
module "iam" {
  source       = "../../modules/iam"
  project_name = var.project_name
}

# --- 3. Public-Facing Load Balancer Layer ---
module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
}

module "eic_endpoint" {
  source = "../../modules/eic_endpoint"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  # Place the endpoint in the first private app subnet
  subnet_id    = module.vpc.app_subnet_ids[0] 
}

# 4. Application Configuration Layer 
module "ec2" {
  source = "../../modules/ec2"

  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  iam_instance_profile_name = module.iam.instance_profile_name
  aws_region = var.aws_region
  key_name = aws_key_pair.app_key_pair.key_name
  eic_endpoint_security_group_id = module.eic_endpoint.security_group_id
  
  # Connects to the ALB by allowing traffic from its security group
  alb_security_group_id     = module.alb.alb_security_group_id
  
  # Inject database credentials into the launch template's user_data
  db_endpoint               = module.rds.db_endpoint
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = local.db_password
}

# --- 5. Application Compute & Scaling Layer ---
module "autoscaling" {
  source = "../../modules/autoscaling"

  project_name = var.project_name
  
  # Uses the blueprint from the EC2 module
  launch_template_id    = module.ec2.launch_template_id
  
  # Launches instances into the private app subnets
  vpc_zone_identifier   = module.vpc.app_subnet_ids
  
  # Registers new instances with the ALB's target group
  target_group_arns     = [module.alb.target_group_arn]
}

# --- 6. Data Layer ---
module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  db_name      = var.db_name
  db_username  = var.db_username
  db_password  = local.db_password
  
  # Deploys the DB into the private data subnets
  subnet_ids   = module.vpc.data_subnet_ids
  vpc_id       = module.vpc.vpc_id
  
  # Connects to the EC2 tier by allowing traffic from its security group
  ec2_security_group_id = module.ec2.ec2_security_group_id
}




resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app_key_pair" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.app_key.public_key_openssh
}

# This is a professional touch: save the private key locally for emergency use
# but ensure it's gitignored.
resource "local_file" "private_key_pem" {
  content  = tls_private_key.app_key.private_key_pem
  filename = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0400" # Read-only for user
}