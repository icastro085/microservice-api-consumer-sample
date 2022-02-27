terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
  }
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
    cloudwatch = "http://localhost:4566"
    ec2        = "http://localhost:4566"
    iam        = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    s3         = "http://localhost:4566"
    sqs        = "http://localhost:4566"
  }
}

data "archive_file" "hub_api_zip" {
  type             = "zip"
  output_file_mode = "0666"
  source_dir       = local.hub_api_zip_source
  output_path      = local.hub_api_zip_output
}

resource "aws_sqs_queue" "delivery_request_queue" {
  name = "delivery-request-queue"
}

resource "aws_sqs_queue" "delivery_response_queue" {
  name       = "delivery-response-queue.fifo"
  fifo_queue = true
}

resource "aws_s3_bucket" "hub_api_bucket" {
  bucket = "hub-api"
}

resource "aws_s3_object" "hub_api_source" {
  bucket = aws_s3_bucket.hub_api_bucket.id
  source = data.archive_file.hub_api_zip.output_path

  key          = local.hub_api_source_key
  content_type = local.hub_api_source_content_type
}

resource "aws_iam_role" "this" {
  name = "hub-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name = "hub-api"

  s3_bucket = aws_s3_bucket.hub_api_bucket.id
  s3_key    = aws_s3_object.hub_api_source.key
  role      = aws_iam_role.this.arn

  runtime = "nodejs12.x"
  handler = "index.handler"
}

resource "aws_api_gateway_rest_api" "this" {
  name = "hub-api"
}

resource "aws_api_gateway_method" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id

  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.this.http_method

  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.proxy.id

  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.this.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.this.id,
      aws_api_gateway_integration.proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "hub-api"
}
