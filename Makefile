.PHONY: start
start:
	docker-compose up

.PHONY: stop
stop:
	docker-compose down

.PHONY: logs
logs:
	docker-compose logs -f hub-api

# version work: sqs - 0.11.2
.PHONY: serverless-invoke
serverless-invoke:
	docker-compose exec localstack \
		awslocal lambda invoke --region us-east-2 --function-name hub-api response.json
