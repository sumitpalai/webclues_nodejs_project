provider "aws" {
  region = "ap-south-1"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create Route Table
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Create Subnet
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

# Create Security Group
resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0f58b397bc5c1f2e8"  # Specify your desired AMI ID
  instance_type = "t2.micro"               # Change instance type as needed
  subnet_id     = aws_subnet.subnet.id
  key_name      = "palais"                 # Specify your key pair name for SSH access
  security_groups = [aws_security_group.nginx_sg.id]
  associate_public_ip_address = true       # Optional: Associate a public IP address with the instance

  tags = {
    Name = "nginx-web-server"
  }

  # Userdata to install nginx and start service
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install nginx -y
              service nginx start
              chkconfig nginx on
              EOF
}

