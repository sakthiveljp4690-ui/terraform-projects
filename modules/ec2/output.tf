output "primary_eni" {
    value = aws_instance.free_tier_application_instance.primary_network_interface_id
}

output "instance_id" {
    value = aws_instance.free_tier_application_instance.id
}