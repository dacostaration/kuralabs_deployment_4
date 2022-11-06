variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "us-east-2"
  
}

resource "aws_instance" "web_server01" {
  ami = "ami-097a2df4ac947655f"
  instance_type = "t2.micro"
  key_name = "jenkins2"
  subnet_id = aws_subnet.subnet1.id         #....add vpc 
  vpc_security_group_ids = [aws_security_group.web_ssh.id]

  user_data = "${file("deploy.sh")}"

  tags = {
    "Name" : "Webserver001.2"
  }
  
}

# BEGIN: Deployment 4 - VPC ############
# VPC
resource "aws_vpc" "deployment04-vpc" {
  cidr_block           = "172.19.0.0/16"
  enable_dns_hostnames = "true"
}

# ELASTIC IP 
resource "aws_eip" "nat_eip_prob" {
  vpc = true
}

# SUBNET 1
resource "aws_subnet" "subnet1" {
  cidr_block              = "172.19.0.0/18"
  vpc_id                  = aws_vpc.deployment04-vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "gw_1" {
  vpc_id = aws_vpc.deployment04-vpc.id
}

# ROUTE TABLE
resource "aws_route_table" "route_table1" {
  vpc_id = aws_vpc.deployment04-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_1.id
  }
}

resource "aws_route_table_association" "route-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table1.id
}

# DATA
data "aws_availability_zones" "available" {
  state = "available"
}
# END: Deployment 4 - VPC ############

output "instance_ip" {
  value = aws_instance.web_server01.public_ip
  
}
