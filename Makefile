.PHONY: start
start:
	docker-compose up

.PHONY: stop
stop:
	docker-compose down

.PHONY: logs
logs:
	docker-compose logs -f app

.PHONY: setup
setup:
	docker-compose exec localstack\
		awslocal sqs create-queue --queue-name delivery-request-queue

	docker-compose exec localstack\
		awslocal sqs create-queue --queue-name delivery-response-queue.fifo --attributes FifoQueue=true --region us-east-2

.PHONY: dynamodb
dynamodb:
	docker-compose exec localstack\
		awslocal dynamodb list-tables
