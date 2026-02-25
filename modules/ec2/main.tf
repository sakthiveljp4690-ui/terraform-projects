data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]
    
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_instance" "free_tier_application_instance" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type
    iam_instance_profile = var.ec2_instance_profile
    vpc_security_group_ids = [var.public_security_groups]
    subnet_id = var.public_subnet
    associate_public_ip_address = true
    tags = {
        Name = "terraform-application-public"
    }
}