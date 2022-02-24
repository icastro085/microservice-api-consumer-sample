.PHONY: start
start:
	docker-compose up

.PHONY: stop
stop:
	docker-compose down

.PHONY: logs
logs:
	docker-compose logs -f hub-api

# version work sqs - 0.11.2
.PHONY: setup
setup:
	docker-compose exec localstack \
		awslocal sqs create-queue --queue-name delivery-request-queue --region us-east-2

	docker-compose exec localstack \
		awslocal sqs create-queue --queue-name delivery-response-queue.fifo --attributes FifoQueue=true --region us-east-2

	docker-compose exec localstack \
		awslocal s3api create-bucket --bucket hub-api --region us-east-2

	docker-compose exec localstack \
		awslocal iam create-role --role-name hub-api-role --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": ["lambda.amazonaws.com", "apigateway.amazonaws.com"]}, "Action": "sts:AssumeRole"}]}'

	docker-compose exec localstack \
		awslocal lambda create-function --function-name hub-api --runtime nodejs12.x --role arn:aws:iam::000000000000:role/hub-api-role --handler api-serverless/index.handler --code S3Bucket=hub-api,S3Key=lambda.zip --publish --environment Variables='{SQS_URL_DELIVERY=string,MONGODB_URL=string}'

.PHONY: deploy-serverless
deploy-serverless:
	zip -r -D hub-api.zip api-serverless/
	docker cp hub-api.zip localstack:/tmp/hub-api.zip
	docker-compose exec localstack awslocal s3 cp /tmp/hub-api.zip s3://hub-api/lambda.zip
	docker-compose exec localstack awslocal lambda update-function-code --function-name hub-api --s3-bucket hub-api --s3-key lambda.zip --publish
	
.PHONY: invoke
invoke:
	docker-compose exec localstack \
		awslocal lambda invoke --function-name hub-api hub-api.out
