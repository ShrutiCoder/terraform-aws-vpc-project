resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }

}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private-Subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private-Subnet-2"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-table"
  }

}

resource "aws_route_table_association" "public_rt_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public-rt.id

}

resource "aws_route_table_association" "public_rt_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public-rt.id

}
resource "aws_eip" "nat_eip" {
    domain = "vpc"

    tags = {
      Name= "nat-eip"
    }
  
}
resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet_2.id

    tags={
        Name= "main_nat_gateway"
    }

    depends_on = [ aws_internet_gateway.igw ]
  
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }
  tags = {
    Name= "private-route-table"
  }
}

resource "aws_route_table_association" "private_rt_assoc_1" {
    subnet_id= aws_subnet.private_subnet_1.id
    route_table_id= aws_route_table.private_rt.id
  
}
resource "aws_route_table_association" "private_rt_assoc_2" {
    subnet_id= aws_subnet.private_subnet_2.id
    route_table_id= aws_route_table.private_rt.id
  
}

resource "aws_security_group" "bastion_sg" {
    name = "bastion-sg"
    description = "Allow SSH"
    vpc_id = aws_vpc.main.id

    ingress {
        description = "SSH Access"
        from_port = 22
        to_port = 22
        protocol = "tcp"

        cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name= "bastion-sg"
  }
}

resource "aws_instance" "bastion_host" {
    ami = "ami-0a59ec92177ec3fad"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet_1.id
    key_name = "terraform-key"
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]
    associate_public_ip_address = true
  
  tags = {
    Name= "bastion_host"
  }
}

resource "aws_security_group" "private_app_sg" {
    name= "private-app-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        description = "SSH from Bastion"
        from_port = 22
        to_port = 22
        protocol = "tcp"

        security_groups = [aws_security_group.bastion_sg.id]
    }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name= "private_app_sg"
  }
}

resource "aws_instance" "private_app_server" {
    ami = "ami-0a59ec92177ec3fad"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private_subnet_1.id
    key_name = "terraform-key"
    vpc_security_group_ids = [aws_security_group.private_app_sg.id]

    tags = {
      Name="private_app_server"
    }
  
}

