#provider
provider "aws" {
  region = "us-east-1"
}

#configuracao vpc e subnet
resource "aws_vpc" "vpc-bill" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-bill"
  }
}

#regra libera ssh de entrada internet > vm
resource "aws_security_group" "libera-ssh" {
  name        = "libera-ssh"
  vpc_id      = aws_vpc.vpc-bill.id
  description = "Permite acesso ssh as instancias"

  ingress {
    from_port   = 22
    to_port     = 22
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

#criacao da subnet publica
resource "aws_subnet" "public-subnet-bill-01" {
  vpc_id     = aws_vpc.vpc-bill.id
  cidr_block = "192.168.0.0/24"

  tags = {
    Name = "public-subnet-bill-01"
  }
}

#criacao do internet gateway
resource "aws_internet_gateway" "bill-igw" {
  vpc_id = aws_vpc.vpc-bill.id

  tags = {
    Name = "bill-igw"
  }
}

#criacao da tabela de roteamento
resource "aws_route_table" "bill_rt" {
  vpc_id = aws_vpc.vpc-bill.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bill-igw.id
  }

  tags = {
    Name = "bill_rt"
  }
}

#criacao da rota default para Acesso a internet
resource "aws_route" "aws_route_table_bill_to_internet" {
  route_table_id         = aws_route_table.bill_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bill-igw.id
}

#associacao da subnet publica com a tabela de roteamento
resource "aws_route_table_association" "bill_pub_association" {
  subnet_id      = aws_subnet.public-subnet-bill-01.id
  route_table_id = aws_route_table.bill_rt.id
}
#

#instancia ec2
resource "aws_instance" "vm-ec2" {
  count                       = 1
  ami                         = "ami-07d02ee1eeb0c996c"
  instance_type               = "t3.medium"
  key_name                    = "chave_aws"
  subnet_id                   = aws_subnet.public-subnet-bill-01.id
  vpc_security_group_ids      = [ aws_security_group.libera-ssh.id ]
  associate_public_ip_address = true
  
  root_block_device {
  volume_size = 40
  volume_type = "gp2"
  encrypted   = false
  }

  tags = {
    name = "vm-ec2-${count.index}"
  }
}
