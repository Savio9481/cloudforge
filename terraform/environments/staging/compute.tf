module "compute" {
  source = "../../modules/compute"

  environment                 = "staging"
  ami_id                      = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.network.public_subnet_id
  security_group_id           = aws_security_group.cloudforge.id
  iam_instance_profile        = aws_iam_instance_profile.cloudforge_ec2.name
  root_volume_size            = 30
  associate_public_ip_address = true
}