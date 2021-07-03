terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.48"
    }
  }
  required_version = ">= 1.0"
}

// Localstack integration: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/custom-service-endpoints#localstack
provider "aws" {
  access_key = "mock_access_key"
  region = "eu-west-1"
  s3_force_path_style = true
  secret_key = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    apigateway = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    es = "http://localhost:4566"
    iam = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
  }
}

resource "aws_instance" "app_server" {
  // Ubuntu 20.10 AMI in eu-west-1. See https://cloud-images.ubuntu.com/locator/ec2/
  ami = "ami-0b66abce162eb2baf"
  instance_type = "t2.micro"
}
