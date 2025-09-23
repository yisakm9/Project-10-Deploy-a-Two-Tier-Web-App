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
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # This filter is updated to find the AL2023 AMI
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
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
  image_id      = data.aws_ami.amazon_linux_2023.id 
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
              set -e

              echo "Updating packages and installing dependencies..."
              dnf update -y
              dnf install -y git-all nodejs

              echo "Cloning official Docker sample application repository..."
              git clone https://github.com/docker/getting-started-app.git /home/ec2-user/app

              echo "Creating .env file with database credentials..."
              cat > /home/ec2-user/app/src/.env <<ENV
              MYSQL_HOST=${var.db_endpoint}
              MYSQL_USER=${var.db_username}
              MYSQL_PASSWORD='${var.db_password}'
              MYSQL_DB=${var.db_name}
              APP_PORT=3000
              ENV
              
              echo "Installing application dependencies from the /src directory..."
              cd /home/ec2-user/app/src
              npm install

              echo "Setting ownership of the entire app directory..."
              chown -R ec2-user:ec2-user /home/ec2-user/app
              
              echo "Setup script finished successfully."
              SETUP_SCRIPT

              chmod +x /usr/local/bin/app-setup.sh

              # The setup service (runs once)
              cat > /etc/systemd/system/app-setup.service << SETUP_SERVICE
              [Unit]
              Description=Application Setup Script
              Before=todoapp.service
              Requires=network-online.target
              After=network-online.target
              [Service]
              Type=oneshot
              ExecStart=/usr/local/bin/app-setup.sh
              RemainAfterExit=yes
              [Install]
              WantedBy=multi-user.target
              SETUP_SERVICE

              # The main application service (restarts on failure)
              cat > /etc/systemd/system/todoapp.service << APP_SERVICE
              [Unit]
              Description=Node.js Todo App
              Requires=app-setup.service
              After=app-setup.service
              [Service]
              User=ec2-user
              Group=ec2-user
              WorkingDirectory=/home/ec2-user/app/src
              # THIS IS THE FINAL FIX: Correct filename from server.js to app.js
              ExecStart=/usr/bin/node app.js
              Restart=always
              RestartSec=10
              [Install]
              WantedBy=multi-user.target
              APP_SERVICE

              echo "Enabling and starting services..."
              systemctl daemon-reload
              systemctl enable app-setup.service
              systemctl enable todoapp.service
              systemctl start app-setup.service
              
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