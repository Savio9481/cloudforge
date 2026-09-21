output "vpc_id" {
  description = "CloudForge Staging VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "CloudForge Staging public subnet ID"
  value       = module.network.public_subnet_id
}

output "internet_gateway_id" {
  description = "CloudForge Staging Internet Gateway ID"
  value       = module.network.internet_gateway_id
}

output "ec2_instance_id" {
  description = "CloudForge Staging EC2 instance ID"
  value       = module.compute.instance_id
}

output "ec2_public_ip" {
  description = "CloudForge Staging EC2 public IP"
  value       = module.compute.public_ip
}

output "ec2_public_dns" {
  description = "CloudForge Staging EC2 public DNS"
  value       = module.compute.public_dns
}

output "security_group_id" {
  description = "CloudForge Staging security group ID"
  value       = aws_security_group.cloudforge.id
}