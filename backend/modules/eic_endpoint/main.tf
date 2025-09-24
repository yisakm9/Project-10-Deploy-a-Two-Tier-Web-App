# This security group will be attached to the endpoint itself.
resource "aws_security_group" "eic_endpoint" {
  name   = "${var.project_name}-eic-endpoint-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-eic-endpoint-sg"
  }
}

# This is the EC2 Instance Connect Endpoint resource.
resource "aws_ec2_instance_connect_endpoint" "main" {
  subnet_id          = var.subnet_id
  security_group_ids = [aws_security_group.eic_endpoint.id]

  tags = {
    Name = "${var.project_name}-eic-endpoint"
  }
}