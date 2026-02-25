resource "aws_vpc" "free_tier_vpc" {
    enable_dns_hostnames = true
    cidr_block = var.vpc_range
    tags = {
        Name = "terraform-free-tier-vpc"
    }
}

resource "aws_route_table" "free_tier_public_routetable" {
  vpc_id = aws_vpc.free_tier_vpc.id
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "free_tier_private_routetable" {
  vpc_id = aws_vpc.free_tier_vpc.id
  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route" "public_route" {
    route_table_id = aws_route_table.free_tier_public_routetable.id
    gateway_id = aws_internet_gateway.free_tier_igw.id
    destination_cidr_block = var.internet_cidr
}

resource "aws_route" "private_route" {
    route_table_id = aws_route_table.free_tier_private_routetable.id
    network_interface_id = var.primary_eni
    destination_cidr_block = var.internet_cidr
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.free_tier_vpc.id
    cidr_block = var.public_network_range
    tags = {
      Name = "public"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.free_tier_vpc.id
    cidr_block = var.private_network_range
    tags = {
      Name = "private"
    }
}

resource "aws_route_table_association" "public_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.free_tier_public_routetable.id
}

resource "aws_route_table_association" "private_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.free_tier_private_routetable.id
}

resource "aws_internet_gateway" "free_tier_igw" {
    vpc_id = aws_vpc.free_tier_vpc.id
    tags = {
      Name = "main"
    }
}