.PHONY: deploy
deploy: deploy
	@echo "Deploying resources"

	@aws s3api put-object --endpoint-url http://localhost:4566 --profile localstack \
		--bucket hub-static-uploaded --key text.txt --body=text.txt

	@echo "Finish"

logs:
	@aws --endpoint-url=http://localhost:4566 --profile localstack \
		logs tail '/aws/lambda/hub-api' --follow