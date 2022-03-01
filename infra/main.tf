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

# message queue setup

resource "aws_sqs_queue" "delivery_request_queue" {
  name = "delivery-request-queue"
}

resource "aws_sqs_queue" "delivery_response_queue" {
  name       = "delivery-response-queue.fifo"
  fifo_queue = true
}

resource "aws_sqs_queue" "webhook_queue" {
  name       = "webhook-queue.fifo"
  fifo_queue = true
}

output "hub-queue-webhook" {
  value = aws_sqs_queue.webhook_queue.id
}

# lambda and apigateway setup

resource "aws_s3_bucket" "this" {
  bucket = "hub-api"
}

resource "aws_s3_object" "this" {
  bucket = aws_s3_bucket.this.id
  source = "${path.module}/resources/lambda/function.zip"

  key          = local.hub_api_source_key
  content_type = local.hub_api_source_content_type
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "hub-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_lambda_function" "this" {
  function_name = "hub-api"

  s3_bucket = aws_s3_bucket.this.id
  s3_key    = aws_s3_object.this.key
  role      = aws_iam_role.this.arn

  runtime = "nodejs14.x"
  handler = "index.handler"
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = aws_sqs_queue.webhook_queue.arn
  function_name    = aws_lambda_function.this.arn
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

  integration_http_method = "POST"
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

  integration_http_method = "POST"
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

# website storage

module "hub_spa_root_bucket" {
  source = "./modules/s3-website"
  bucket = "hub-spa-root"
}

output "hub_spa_root_bucket_arn" {
  value = module.hub_spa_root_bucket.arn
}

output "hub_spa_root_bucket_regional_domain_name" {
  value = module.hub_spa_root_bucket.regional_domain_name
}

output "hub_spa_root_bucket_website_endpoint" {
  value = module.hub_spa_root_bucket.website_endpoint
}
