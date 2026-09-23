terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CloudForge"
      Environment = "staging"
      ManagedBy   = "Terraform"
      Owner       = "learning"
      AutoDestroy = "true"
    }
  }
}

module "network" {
  source = "../../modules/network"

  environment        = "staging"
  vpc_cidr           = "10.1.0.0/16"
  public_subnet_cidr = "10.1.1.0/24"
  availability_zone  = "us-east-1b"
}