# Define VPC
resource "aws_vpc" "aditya_vpc" {
  cidr_block = "80.0.0.0/16"
  tags = {
    Name = "aditya_vpc"
}
}

# Define adPub subnets
resource "aws_subnet" "adPub_subnet_1" {
  vpc_id     = aws_vpc.aditya_vpc.id
  cidr_block = "80.0.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "adPub_subnet_1"
}
}

resource "aws_subnet" "adPub_subnet_2" {
  vpc_id     = aws_vpc.aditya_vpc.id
  cidr_block = "80.0.2.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "adPub_subnet_2"
}
}

# Define adPvt subnets
resource "aws_subnet" "adPvt_subnet_1" {
  vpc_id     = aws_vpc.aditya_vpc.id
  cidr_block = "80.0.3.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "adPvt_subnet_1"
}
}

resource "aws_subnet" "adPvt_subnet_2" {
  vpc_id     = aws_vpc.aditya_vpc.id
  cidr_block = "80.0.4.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "adPvt_subnet_2"
}
}

# Define internet gateway
resource "aws_internet_gateway" "aditya_igw" {
  vpc_id = aws_vpc.aditya_vpc.id
  tags = {
    Name = "aditya_igw"
}
}

# Define route table for adPub subnets
resource "aws_route_table" "adPub_route_table" {
  vpc_id = aws_vpc.aditya_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aditya_igw.id
  }
  tags = {
    Name = "adPub_route_table"
}
}

# Define route table for adPvt subnets
resource "aws_route_table" "adPvt_route_table" {
  vpc_id = aws_vpc.aditya_vpc.id

  tags = {
    Name = "adPvt_route_table"
}
}

# Associate adPub subnets with adPub route table
resource "aws_route_table_association" "adPub_subnet_1_association" {
  subnet_id      = aws_subnet.adPub_subnet_1.id
  route_table_id = aws_route_table.adPub_route_table.id
  
}

resource "aws_route_table_association" "adPub_subnet_2_association" {
  subnet_id      = aws_subnet.adPub_subnet_2.id
  route_table_id = aws_route_table.adPub_route_table.id
}


# Associate adPvt subnets with adPvt route table
resource "aws_route_table_association" "adPvt_subnet_1_association" {
  subnet_id      = aws_subnet.adPvt_subnet_1.id
  route_table_id = aws_route_table.adPvt_route_table.id
  
}

resource "aws_route_table_association" "adPvt_subnet_2_association" {
  subnet_id      = aws_subnet.adPvt_subnet_2.id
  route_table_id = aws_route_table.adPvt_route_table.id
}


# Define security group for EC2 instances
resource "aws_security_group" "aditya_sg" {
  name        = "aditya_sg"
  vpc_id      = aws_vpc.aditya_vpc.id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags = {
    Name = "aditya_sg"
}
}

# Define EC2 instances in adPub subnets
resource "aws_instance" "adPub_instance_1" {
  ami           = "ami-0d81306eddc614a45"
  instance_type = "t2.micro"
  key_name = "aditya"
  subnet_id     = aws_subnet.adPub_subnet_1.id
  availability_zone = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.aditya_sg.id]
  depends_on = [aws_internet_gateway.aditya_igw]
  associate_public_ip_address = true
  tags = {
    Name = "adPub_instance_01"
}
}

# Define EC2 instances in adPub subnets
resource "aws_instance" "adPub_instance_2" {
  ami           = "ami-0d81306eddc614a45"
  instance_type = "t2.micro"
  key_name = "aditya"
  subnet_id     = aws_subnet.adPub_subnet_2.id
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.aditya_sg.id]
  depends_on = [aws_internet_gateway.aditya_igw]
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    sudo su -
    yum update -y
    yum install docker -y
    docker systemctl start docker
    systemctl start docker
    systemctl enable docker
    EOF
  tags = {
    Name = "adPub_instance_02"
}
}

# Create Subnet Gropu for RDS
resource "aws_db_subnet_group" "aditya_sub" {
  name       = "aditya"

  subnet_ids = [
     aws_subnet.adPvt_subnet_2.id,
     aws_subnet.adPvt_subnet_1.id
  ]

  tags = {
    Name = "adityaSubnet"
  }
}

# Creating RDS

resource "aws_db_instance" "adityadatabase" {
 identifier = "adityadatabase"
 db_name="adityadatabase"
 username="root"
 password="cloudthat"
 engine = "mysql"
 engine_version = "8.0"
 instance_class = "db.t3.micro"
 allocated_storage = 20
 storage_type = "gp2"
 storage_encrypted = true
 skip_final_snapshot = true
 db_subnet_group_name = aws_db_subnet_group.aditya_sub.name
 vpc_security_group_ids = [aws_security_group.aditya_sg.id]
 availability_zone = "ap-south-1a"
}