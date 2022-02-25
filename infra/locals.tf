locals {
  hub_api_cp_lambda_key          = "lambda.zip"
  hub_api_cp_lambda_source       = "${path.module}/../api-serverless"
  hub_api_cp_lambda_source_path  = "${path.module}/../.tmp/${local.hub_api_cp_lambda_key}"
  hub_api_cp_lambda_content_type = "application/zip"
}
