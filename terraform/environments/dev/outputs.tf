output "vpc_id" {
  description = "CloudForge VPC ID"
  value       = aws_vpc.cloudforge.id
}

output "public_subnet_id" {
  description = "CloudForge public subnet ID"
  value       = aws_subnet.cloudforge_public.id
}

output "internet_gateway_id" {
  description = "CloudForge Internet Gateway ID"
  value       = aws_internet_gateway.cloudforge.id
}


output "ec2_instance_id" {
  description = "CloudForge EC2 instance ID"
  value       = aws_instance.cloudforge.id
}

output "ec2_public_ip" {
  description = "CloudForge EC2 public IP"
  value       = aws_instance.cloudforge.public_ip
}

output "ec2_public_dns" {
  description = "CloudForge EC2 public DNS"
  value       = aws_instance.cloudforge.public_dns
}

output "security_group_id" {
  description = "CloudForge security group ID"
  value       = aws_security_group.cloudforge.id
}