
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "proj-vpc" {

  cidr_block = "10.0.0.0/16"

}

# Setting up the subnet
resource "aws_subnet" "proj-subnet" {

  vpc_id     = aws_vpc.proj-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {

    Name = "subnet1"

  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "proj-ig" {

  vpc_id = aws_vpc.proj-vpc.id
  tags = {
    Name = "gateway1"
  }
}

# Setting up the route table
resource "aws_route_table" "proj-rt" {

  vpc_id = aws_vpc.proj-vpc.id
  route {

    # pointing to the internet
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proj-ig.id

  }

  route {

    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.proj-ig.id

  }

  tags = {

    Name = "rt1"

  }
}


# Creating a Security Group
resource "aws_security_group" "proj-sg" {

  name        = "proj-sg"
  description = "Enable web traffic for the project"
  vpc_id      = aws_vpc.proj-vpc.id
  ingress {

    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["10.0.1.0/24"]
  }


  ingress {

    from_port = 6433
    to_port = 6433
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    description = "NFS traffic"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    description = "SSH port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    description = "SSH port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }

  tags = {

    Name = "proj-sg1"

  }

}

# Associating the subnet with the route table
resource "aws_route_table_association" "proj-rt-sub-assoc" {
  subnet_id      = aws_subnet.proj-subnet.id
  route_table_id = aws_route_table.proj-rt.id
}


module "ec2_instance" {

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = {
 
    "kubemaster" = { vm_size = "t2.medium", private_ips="10.0.1.10" }
    
    "kubeworker-1" = { vm_size = "t2.medium", private_ips="10.0.1.11" }
    
    "kubeworker-2" = { vm_size = "t2.medium", private_ips="10.0.1.12"}

    "nfs-server" = { vm_size = "t2.micro", private_ips="10.0.1.13"}

    

 
  }
 
  name = each.key
  ami                    = "ami-00874d747dde814fa"
  instance_type          = each.value.vm_size
  key_name               = "demo"
  monitoring             = true
  private_ip             = each.value.private_ips
  subnet_id                   = aws_subnet.proj-subnet.id
  vpc_security_group_ids      = [aws_security_group.proj-sg.id]
  associate_public_ip_address = true
  

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}





output print_public_ip {

  //value = "${module.ec2_instance}"
  value = "${module.ec2_instance}"
}
 

