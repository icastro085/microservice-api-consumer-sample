.PHONY: deploy
deploy: deploy
	@echo "Deploying resources"

	@aws s3 cp --endpoint-url http://localhost:4566 --profile localstack \
		index.html s3://hub-spa-root

	@echo "Finish"