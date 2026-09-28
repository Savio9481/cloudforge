resource "aws_iam_role" "cloudforge_ec2" {
  name = "cloudforge-staging-ec2-role"

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
    Name = "cloudforge-staging-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudforge_ssm" {
  role       = aws_iam_role.cloudforge_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cloudforge_ec2" {
  name = "cloudforge-staging-ec2-profile"
  role = aws_iam_role.cloudforge_ec2.name
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "cloudforge-staging-cloudwatch-logs"
  role = aws_iam_role.cloudforge_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.cloudforge_staging.arn}:*"
      }
    ]
  })
}