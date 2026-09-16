resource "aws_iam_role" "cloudforge_ec2" {
  name = "cloudforge-dev-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "cloudforge-dev-ec2-role"
  }
}


resource "aws_iam_role_policy_attachment" "cloudforge_ssm" {
  role       = aws_iam_role.cloudforge_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "cloudforge_ec2" {
  name = "cloudforge-dev-ec2-profile"
  role = aws_iam_role.cloudforge_ec2.name
}