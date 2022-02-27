init:
# terraform init -backend=true -backend-config="bucket.hcl"
	terraform init

plan:
	terraform plan -out="tfplan.out"

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

validate:
	terraform validate