TF_DIR ?= terraform-cluster

.PHONY: plan up down

plan:
	cd $(TF_DIR) && terraform fmt -recursive
	cd $(TF_DIR) && terraform init -input=false
	cd $(TF_DIR) && terraform validate
	cd $(TF_DIR) && terraform plan -input=false -out=tfplan

up: plan
	cd $(TF_DIR) && terraform apply -input=false tfplan

down:
	cd $(TF_DIR) && terraform destroy -auto-approve
