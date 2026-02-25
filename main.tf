module "iam" {
    source = "./modules/iam"
}

module "security_groups" {
    source = "./modules/sg"
    internet_cidr = var.internet_cidr
    private_network_range = var.private_network_range
    vpc_id = module.vpc.vpc_id
}

module "ec2" {
    source = "./modules/ec2"
    public_subnet = module.vpc.public_subnet
    instance_type = var.instance_type
    ec2_instance_profile = module.iam.ec2_instance_profile
    public_security_groups = module.security_groups.public_security_groups
}

module "vpc" {
    source = "./modules/vpc"
    vpc_range = var.vpc_range
    public_network_range = var.public_network_range
    private_network_range = var.private_network_range
    internet_cidr = var.internet_cidr
    primary_eni = module.ec2.primary_eni
}

