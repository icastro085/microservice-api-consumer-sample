# output "hub-queue-request" {
#   value = aws_sqs_queue.delivery_request_queue.arn
# }

# output "hub-queue-request_url" {
#   value = aws_sqs_queue.delivery_request_queue.url
# }

# output "hub-queue-response" {
#   value = aws_sqs_queue.delivery_response_queue.arn
# }

# output "hub-queue-response_url" {
#   value = aws_sqs_queue.delivery_response_queue.url
# }

output "hub-api-bucket" {
  value = aws_s3_bucket.this.arn
}

output "hub-api-bucket_domain_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}

output "hub-role" {
  value = aws_iam_role.this.arn
}

output "hub-api-lambda" {
  value = aws_lambda_function.this.arn
}

output "hub-apigateway-url" {
  value = aws_api_gateway_stage.this.invoke_url
}

output "hub-apigateway-url-local" {
  value = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.this.id}/${aws_api_gateway_stage.this.stage_name}/_user_request_/"
}

# output "hub_api_log" {
#   value = aws_cloudwatch_log_group.hub_api_log.arn
# }

output "env" {
  value = var.env
}
