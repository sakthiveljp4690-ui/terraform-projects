output "public_ip" {
    value = aws_instance.free_tier_nat_instance.public_ip
}

output "private_ip" {
    value = aws_instance.free_tier_private_instance.public_ip
}
