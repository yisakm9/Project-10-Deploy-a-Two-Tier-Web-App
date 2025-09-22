# backend/modules/alb/main.tf

# 1. ALB Security Group
# This acts as a firewall for the load balancer itself.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = var.vpc_id

  # Ingress Rule: Allow HTTP traffic on port 80 from anywhere on the internet.
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress Rule: Allow all outbound traffic. The ALB needs this to send
  # traffic to the EC2 instances in the private subnets.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# 2. Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 3. Target Group
# This defines a group of targets (our EC2 instances) that the ALB will route traffic to.
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 3000 # The port our Node.js app listens on
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health Check: The ALB will send requests to this path to determine if an
  # instance is healthy. If it gets a 200 OK response, the instance is healthy.
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-target-group"
  }
}

# 4. Listener
# This checks for incoming connections on a specific port and protocol.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default Action: If a request comes in on port 80, forward it
  # to our main target group.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}