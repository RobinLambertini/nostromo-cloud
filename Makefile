.PHONY: init plan provision configure deploy ping reinstall

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan -var-file=secret.tfvars

provision:
	cd terraform && terraform apply -var-file=secret.tfvars

configure:
	cd ansible && ansible-playbook main.yml --ask-vault-pass

deploy: plan provision configure

ping:
	cd ansible && ansible nostromo -m ping
