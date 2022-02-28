locals {
  hub_api_source_key          = "function.zip"
  hub_api_source_content_type = "application/zip"

  hub_api_zip_source = "${path.module}/../api-serverless"
  hub_api_zip_output = "${path.module}/../.tmp/${local.hub_api_source_key}"
}
