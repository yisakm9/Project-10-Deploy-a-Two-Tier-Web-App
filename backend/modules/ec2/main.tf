# backend/modules/ec2/main.tf

# 1. EC2 Security Group
# This acts as a firewall for our application instances.
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow traffic from ALB and allow all outbound"
  vpc_id      = var.vpc_id

  # Ingress Rule: Allow traffic on port 3000 (for our Node.js app)
  # only from the Application Load Balancer's security group.
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Egress Rule: Allow all outbound traffic. This allows our instances to
  # communicate with the RDS database and reach the internet (via the NAT Gateway)
  # for tasks like cloning the Git repo and installing packages.
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
# This is a best practice to avoid using outdated or hardcoded AMIs.
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
# This defines the full configuration for any instance we want to launch.
# The Auto Scaling Group will use this template as a blueprint.
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # User Data script for automated bootstrapping on first launch.
  # It is base64 encoded by Terraform.
 user_data = base64encode(<<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              # Create a setup script that will be executed by a one-shot systemd service
              cat > /usr/local/bin/app-setup.sh << 'SETUP_SCRIPT'
              #!/bin/bash
              set -e # Exit immediately if a command exits with a non-zero status.

              echo "Updating packages..."
              yum update -y
              yum install -y git

              echo "Installing Node.js 18.x..."
              curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
              yum install -y nodejs

              echo "Cloning application repository into /home/ec2-user/app..."
              git clone https://github.com/cloudacademy/nodejs-todo-app.git /home/ec2-user/app

              echo "Creating .env file with database credentials..."
              cat > /home/ec2-user/app/.env <<ENV
              DB_HOST=${var.db_endpoint}
              DB_PORT=3306
              DB_USER=${var.db_username}
              DB_PASSWORD='${var.db_password}'
              DB_DATABASE=${var.db_name}
              APP_PORT=3000
              ENV
              
              echo "Installing application dependencies..."
              cd /home/ec2-user/app
              npm install

              echo "Setting ownership of the app directory..."
              chown -R ec2-user:ec2-user /home/ec2-user/app
              
              echo "Setup script finished successfully."
              SETUP_SCRIPT

              # Make the setup script executable
              chmod +x /usr/local/bin/app-setup.sh

              # Create a one-shot systemd service to run our setup script
              cat > /etc/systemd/system/app-setup.service << SETUP_SERVICE
              [Unit]
              Description=Application Setup Script
              # This service must run before our main application service
              Before=todoapp.service
              # It needs the network to be online to clone git repo
              Requires=network-online.target
              After=network-online.target

              [Service]
              Type=oneshot
              ExecStart=/usr/local/bin/app-setup.sh
              RemainAfterExit=yes

              [Install]
              WantedBy=multi-user.target
              SETUP_SERVICE

              # Create the main application service file
              cat > /etc/systemd/system/todoapp.service << APP_SERVICE
              [Unit]
              Description=Node.js Todo App
              # This is the critical line: It will not start until app-setup.service has succeeded
              Requires=app-setup.service
              After=app-setup.service

              [Service]
              User=ec2-user
              Group=ec2-user
              WorkingDirectory=/home/ec2-user/app
              ExecStart=/usr/bin/node server.js
              Restart=always
              RestartSec=10
              
              [Install]
              WantedBy=multi-user.target
              APP_SERVICE

              echo "Enabling services..."
              systemctl daemon-reload
              systemctl enable app-setup.service
              systemctl enable todoapp.service
              
              echo "Starting services..."
              systemctl start app-setup.service
              systemctl start todoapp.service
              
              echo "User data script finished."
              EOF
  )

  # Ensures tags are applied to network interfaces for easier cost tracking.
  tag_specifications {
    resource_type = "network-interface"
    tags = {
      Name = "${var.project_name}-eni"
    }
  }

  tags = {
    Name = "${var.project_name}-launch-template"
  }
}