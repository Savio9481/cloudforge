resource "aws_cloudwatch_log_group" "cloudforge_staging" {
  name              = "/cloudforge/staging"
  retention_in_days = 3

  tags = {
    Name = "cloudforge-staging-logs"
  }
}