# backend/modules/iam/main.tf

# 1. IAM Role for EC2
# This defines the role and its trust policy, which specifies that only
# the EC2 service is allowed to assume this role.
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  # The trust policy, written in HCL using jsonencode for clarity and safety.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# 2. IAM Policy Attachment for SSM
# This attaches the AWS-managed policy that grants the permissions
# required for AWS Systems Manager to manage the instance.
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 3. IAM Instance Profile
# This is the container for the IAM role that can be passed to an EC2 instance.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}