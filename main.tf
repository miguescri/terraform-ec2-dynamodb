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
    dynamodb = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    es = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "dynamodb_full_access_profile"
  role = aws_iam_role.role.name
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "role" {
  name = "dynamodb_full_access_role"
  assume_role_policy = "{}"
  // Managed FullAccess policy https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/using-identity-based-policies.html#access-policy-examples-aws-managed
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "app_server" {
  // Ubuntu 20.10 AMI in eu-west-1. See https://cloud-images.ubuntu.com/locator/ec2/
  ami = "ami-0b66abce162eb2baf"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  user_data = "echo 'DYNAMODB_TABLE_ARN=${aws_dynamodb_table.db_table.arn}' >> /etc/environment"
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "db_table" {
  name = "Users"
  billing_mode = "PROVISIONED"
  read_capacity = 20
  write_capacity = 20
  hash_key = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}
