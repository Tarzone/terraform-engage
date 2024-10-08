provider "aws" {
  region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}
variable private_key_location {}
# variable my_pub_key {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block 
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

# Creates a route table (non-default) with igw

# resource "aws_route_table" "myapp-route_table" {
#   vpc_id = aws_vpc.myapp-vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name: "${var.env_prefix}-rtb"
#   }
# }

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

# Associates a route table (non-default) to a subnet

# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route_table.id
# }

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}

resource "aws_default_security_group" "default-sg" {

# # create a security group
# resource "aws_security_group" "myapp-sg" {
#   name = "myapp-sg"

  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
  }
  
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name: "${var.env_prefix}-default-sg"
    # Name: "${var.env_prefix}-sg" # sg tag for created sg
  }  
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# Output AMI ID
output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

# Output ec2 Public IP
output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

# Automate Key-Pair Generation

resource "aws_key_pair" "ssh-key" {
  key_name = "server-keyPair"
  # public_key =  var.my_pub_key # Using variable string value
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  # Example set AMI dynamically
  # ami = "ami-0fff1b9a61dec8a5f"
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  # Specify non-default options
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  /* # Manually pass user data
  user_data = <<EOF 
                #!/bin/bash
                sudo yum update -y && sudo yum install docker -y
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                docker run -p 8080:80 nginx
              EOF
  */

  # Input path for user data
  # user_data = file("entry-script.sh")
              
  user_data_replace_on_change = true

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-ec2-run.sh"
  }

  provisioner "remote-exec" {
    # inline = [
    #   # "export ENV=dev",
    #   # "mkdir newdir"
    #   "/home/ec2-user/entry-script-ec2-run.sh"
    # ]
    script = "entry-script.sh"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > output_pub_ip.txt"
  }

  tags = {
    Name: "${var.env_prefix}-server"
  } 
}
