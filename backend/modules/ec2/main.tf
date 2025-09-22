# backend/modules/ec2/main.tf

# 1. EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow traffic from ALB and allow all outbound"
  vpc_id      = var.vpc_id

  # Ingress Rule: Allow traffic on port 3000 (for our Node.js app)
  # only from the Application Load Balancer.
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Egress Rule: Allow all outbound traffic so instances can reach the
  # internet (via NAT Gateway) for updates and the RDS database.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# 2. Data Source to find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 3. Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # This user_data script automates the entire server setup.
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git
              
              # Install Node.js 18.x
              curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
              yum install -y nodejs
              
              # Clone the application repository
              git clone https://github.com/cloudacademy/nodejs-todo-app.git /home/ec2-user/app
              
              # Create the .env file with database credentials
              cat > /home/ec2-user/app/.env <<ENV
              DB_HOST=${var.db_endpoint}
              DB_PORT=3306
              DB_USER=${var.db_username}
              DB_PASSWORD=${var.db_password}
              DB_DATABASE=${var.db_name}
              APP_PORT=3000
              ENV
              
              # Install application dependencies
              cd /home/ec2-user/app
              npm install
              
              # Set ownership of the app directory
              chown -R ec2-user:ec2-user /home/ec2-user/app
              
              # Create a systemd service to run the app
              cat > /etc/systemd/system/todoapp.service <<SERVICE
              [Unit]
              Description=Node.js Todo App
              After=network.target
              
              [Service]
              User=ec2-user
              WorkingDirectory=/home/ec2-user/app
              ExecStart=/usr/bin/node server.js
              Restart=always
              RestartSec=10
              
              [Install]
              WantedBy=multi-user.target
              SERVICE
              
              # Enable and start the service
              systemctl daemon-reload
              systemctl enable todoapp.service
              systemctl start todoapp.service
              EOF
  )

  tags = {
    Name = "${var.project_name}-launch-template"
  }
}

# 4. EC2 Instances
resource "aws_instance" "app_server" {
  # Launch one instance in each of the private app subnets
  count = length(var.subnet_ids)

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  subnet_id = var.subnet_ids[count.index]

  tags = {
    Name = "${var.project_name}-app-server-${count.index + 1}"
  }
}