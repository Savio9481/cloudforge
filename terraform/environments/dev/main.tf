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
      Environment = "dev"
      ManagedBy   = "Terraform"
      Owner       = "learning"
      AutoDestroy = "true"
    }
  }
}

resource "aws_vpc" "cloudforge" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cloudforge-dev-vpc"
  }
}

resource "aws_internet_gateway" "cloudforge" {
  vpc_id = aws_vpc.cloudforge.id

  tags = {
    Name = "cloudforge-dev-igw"
  }
}

resource "aws_subnet" "cloudforge_public" {
  vpc_id                  = aws_vpc.cloudforge.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudforge-dev-public-subnet"
  }
}

resource "aws_route_table" "cloudforge_public" {
  vpc_id = aws_vpc.cloudforge.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudforge.id
  }

  tags = {
    Name = "cloudforge-dev-public-rt"
  }
}


resource "aws_route_table_association" "cloudforge_public" {
  subnet_id      = aws_subnet.cloudforge_public.id
  route_table_id = aws_route_table.cloudforge_public.id
}