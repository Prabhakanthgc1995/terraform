provider "aws" {
  region = "us-west-1"  # Ensure this is correct for your AWS region
}

# Fetch the Default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch All Default Subnets in the Default VPC
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch the Latest Ubuntu AMI (20.04 LTS)
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical AWS Account ID for Ubuntu
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Define Local Values for Tags & Timestamp
locals {
  common_tags = {
    Project    = "Terraform-EC2-Deployment"
    Environment = "Development"
    CreatedBy  = "Terraform"
  }
  creation_time = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())  # Timestamp format
}

# Select a Subnet in a Supported AZ
resource "aws_instance" "dev_instance" {
  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type  # Define this variable in `variables.tf` or as default

  # Picks the first available subnet dynamically (avoids unsupported AZs)
  subnet_id = element(data.aws_subnets.default_subnets.ids, 0)

  tags = merge(
    local.common_tags,
    {
      Name        = "dev-instance"
      CreationTime = local.creation_time
    }
  )
}

# Output Values for Instance ID, Public IP, and AMI Used

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.dev_instance.id  # Correct resource name
}

output "instance_public_ip" {
  description = "EC2 Public IP"
  value       = aws_instance.dev_instance.public_ip  # Correct resource name
}

output "ami_used" {
  description = "AMI ID used for EC2 instance"
  value       = data.aws_ami.ubuntu_latest.id
}

