variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where EC2 will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the EC2 instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile attached to EC2"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "environment" {
  description = "CloudForge environment name"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IPv4 address with the EC2 instance"
  type        = bool
  default     = false
}