variable "aws_region" {
  description = "AWS region for CloudForge Staging"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for CloudForge Staging"
  type        = string
  default     = "m7i-flex.large"
}