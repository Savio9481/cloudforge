resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = var.associate_public_ip_address

  iam_instance_profile = var.iam_instance_profile

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "cloudforge-${var.environment}-ec2"
  }

}