resource "aws_instance" "cloudforge" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.cloudforge_public.id
  vpc_security_group_ids      = [aws_security_group.cloudforge.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.cloudforge_ec2.name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"

    delete_on_termination = true
  }

  tags = {
    Name = "cloudforge-dev-ec2"
  }
}