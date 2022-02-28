build:
	@echo "Compacting resources"
	@zip -rq ../.tmp/function.zip .
	@echo "Finish"

deploy: build
	@echo "Deploying resources"

	@aws s3 cp --endpoint-url http://localhost:4566 --profile localstack \
		../.tmp/function.zip s3://hub-api

	@aws lambda update-function-code --endpoint-url http://localhost:4566 --profile localstack \
		--function-name hub-api \
		--s3-bucket hub-api \
		--s3-key function.zip \
		--publish

	@echo "Finish"