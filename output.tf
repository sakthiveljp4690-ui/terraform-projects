
output "instance_id" {
    value = module.ec2.instance_id
}

output "alb_endpoint" {
    value = module.alb.alb_endpoint
}

output "rds_db_endpoint" {
    value = module.rds.rds_db_endpoint
}