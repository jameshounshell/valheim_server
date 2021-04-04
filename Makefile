tf_dir = examples/personal

init:
	terraform -chdir=$(tf_dir) init

plan: init
	terraform -chdir=$(tf_dir) plan

apply: init plan
	terraform -chdir=$(tf_dir) apply -auto-approve

connect:
	aws ssm start-session --target $(shell terraform -chdir=$(tf_dir) output -json | jq -r '."instance-id".value')

list:
	aws s3 ls --human-readable --recursive $(bucket)

bucket=s3://jah-valheim
download_latest:
	aws s3 cp --recursive $(bucket)/latest latest

precommit:
	pre-commit run -a