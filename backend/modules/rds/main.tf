# backend/modules/rds/main.tf

# 1. DB Subnet Group
# RDS requires a subnet group to know which subnets within the VPC it can use.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 2. RDS Security Group
# This acts as a firewall for the database.
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow inbound traffic from EC2 instances"
  vpc_id      = var.vpc_id

  # Ingress Rule: Allow traffic on the MySQL port (3306) only
  # from the EC2 application security group. This is a key security practice.
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id] # Reference the EC2 SG
  }

  # Egress Rule: Allow all outbound traffic (default is sufficient)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# 3. RDS DB Instance
resource "aws_db_instance" "main" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Professional settings for availability and security
  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = true # NOTE: Set to 'false' in a production environment

  tags = {
    Name = "${var.project_name}-db-instance"
  }
}