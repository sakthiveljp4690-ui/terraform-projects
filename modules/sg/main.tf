data "aws_security_group" "application_sg" {
    id = aws_security_group.public_security_groups.id
}

resource "aws_security_group" "public_security_groups" {
    vpc_id = var.vpc_id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [var.internet_cidr]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.private_network_range]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.internet_cidr]
    }
    tags = {
        Name = "allow public traffic"
    }
}