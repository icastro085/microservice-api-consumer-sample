terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
  }

  # backend "s3" {
  #   bucket  = "hub-api"
  #   encrypt = "false"
  #   key     = "development/terraform.tfstate"
  #   region  = "us-east-2"
  #   profile = "jcpm"
  # }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
  profile    = var.aws_profile

  s3_use_path_style           = var.aws_s3_use_path_style
  skip_credentials_validation = var.aws_skip_credentials_validation
  skip_metadata_api_check     = var.aws_skip_metadata_api_check
  skip_requesting_account_id  = var.aws_skip_requesting_account_id

  endpoints {
    apigateway = "http://localhost:4566"
    iam        = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    s3         = "http://localhost:4566"
    ses        = "http://localhost:4566"
    sns        = "http://localhost:4566"
    sqs        = "http://localhost:4566"
  }
}

data "archive_file" "hub_api_lambda" {
  type             = "zip"
  output_file_mode = "0666"
  source_dir       = local.hub_api_cp_lambda_source
  output_path      = local.hub_api_cp_lambda_source_path
}

resource "aws_sqs_queue" "delivery_request_queue" {
  name = "delivery-request-queue"
}

resource "aws_sqs_queue" "delivery_response_queue" {
  name       = "delivery-response-queue.fifo"
  fifo_queue = true
}

resource "aws_s3_bucket" "hub_api" {
  bucket = "hub-api"
}

resource "aws_s3_object" "hub_api_cp_lambda" {
  bucket       = aws_s3_bucket.hub_api.id
  source       = data.archive_file.hub_api_lambda.output_path
  key          = local.hub_api_cp_lambda_key
  content_type = local.hub_api_cp_lambda_content_type
}

resource "aws_iam_role" "hub_api_role" {
  name = "hub-api-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Effect : "Allow"
        Principal : {
          Service : ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_lambda_function" "hub_api" {
  function_name = "hub-api"

  s3_bucket = aws_s3_bucket.hub_api.id
  s3_key    = aws_s3_object.hub_api_cp_lambda.key
  role      = aws_iam_role.hub_api_role.arn

  runtime = "nodejs12.x"
  handler = "api-serverless/index.handler"
}
