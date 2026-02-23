data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]
    
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

data "aws_security_group" "nat_sg" {
    id = aws_security_group.public_security_groups.id
}

data "aws_security_group" "private_sg" {
    id = aws_security_group.private_security_groups.id
}

data "aws_security_group" "bation_sg" {
    id = aws_security_group.bation_security_groups.id
}


resource "aws_iam_role" "ec2_ssm_role" {
    name = "ec2_ssm_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
    role = aws_iam_role.ec2_ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_instance_profile"
    role = aws_iam_role.ec2_ssm_role.name 
}

resource "aws_security_group" "public_security_groups" {
    vpc_id = aws_vpc.free_tier_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["10.1.2.0/24"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "allow public traffic"
    }
}

resource "aws_security_group" "private_security_groups" {
    vpc_id = aws_vpc.free_tier_vpc.id
    
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [data.aws_security_group.bation_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [data.aws_security_group.nat_sg.id]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [data.aws_security_group.bation_sg.id]
    }
    tags = {
        Name = "allow private traffic"
    }
}

resource "aws_security_group" "bation_security_groups" {
    vpc_id = aws_vpc.free_tier_vpc.id
    
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [data.aws_security_group.private_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "allow traffic for nginx"
    }
}

resource "aws_instance" "free_tier_nat_instance" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    vpc_security_group_ids = [ aws_security_group.public_security_groups.id ]
    subnet_id = aws_subnet.public_subnet.id
    associate_public_ip_address = true
    source_dest_check = false
    user_data = <<-EOF
              #!/bin/bash
              sudo sysctl -w net.ipv4.ip_forward=1
              sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              EOF
    tags = {
        Name = "terraform-nat-instance"
    }
}

resource "aws_instance" "free_tier_bation_host" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    vpc_security_group_ids = [ aws_security_group.bation_security_groups.id ]
    subnet_id = aws_subnet.public_subnet.id
    associate_public_ip_address = true
    tags = {
        Name = "terraform-bation-instance"
    }
}

resource "aws_instance" "free_tier_private_instance" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    vpc_security_group_ids = [ aws_security_group.private_security_groups.id ]
    subnet_id = aws_subnet.private_subnet.id
    user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install nginx -y
              sudo amazon-linux-extras install nginx1
              sudo systemctl start nginx
              sudo systemctl enable nginx
              sudo echo "<h1>Terraform Deployed This Server</h1>" > /usr/share/nginx/html/index.html
              EOF
    tags = {
        Name = "terraform-free-tier"
    }
}

resource "aws_vpc" "free_tier_vpc" {
    enable_dns_hostnames = true
    cidr_block = "10.1.0.0/16"
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
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_route" {
    route_table_id = aws_route_table.free_tier_private_routetable.id
    network_interface_id = aws_instance.free_tier_nat_instance.primary_network_interface_id
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.free_tier_vpc.id
    cidr_block = "10.1.1.0/24"
    tags = {
      Name = "public"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.free_tier_vpc.id
    cidr_block = "10.1.2.0/24"
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

