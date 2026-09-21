resource "aws_security_group" "cloudforge" {
  name        = "cloudforge-staging-sg"
  description = "Security group for CloudForge staging EC2"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "CloudForge API"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudforge-staging-sg"
  }
}