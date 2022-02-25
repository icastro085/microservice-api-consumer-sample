output "hub-queue-request" {
  value = aws_sqs_queue.delivery_request_queue.arn
}

output "hub-queue-request_url" {
  value = aws_sqs_queue.delivery_request_queue.url
}

output "hub-queue-response" {
  value = aws_sqs_queue.delivery_response_queue.arn
}

output "hub-queue-response_url" {
  value = aws_sqs_queue.delivery_response_queue.url
}

output "hub-api-bucket" {
  value = aws_s3_bucket.hub_api.arn
}

output "hub-api-bucket_domain_name" {
  value = aws_s3_bucket.hub_api.bucket_domain_name
}

output "hub-role" {
  value = aws_iam_role.hub_api_role.arn
}

output "hub-api-lambda" {
  value = aws_lambda_function.hub_api.arn
}
