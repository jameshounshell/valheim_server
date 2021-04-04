Valheim Server
==============
This Terraform module will create a small Valheim server in AWS

Server is configured to load world backups from AWS S3 and send a new backup to S3 before shutdown.

THIS COSTS MONEY. Running a t3.medium costs roughly 30$ a month

Resources Created By This Terraform Module:
- IAM role for s3 and AWS SSM sessions (AWS ssh equivalent)
- Server (t3.medium)
- Security Group to only allow UDP ingresss on ports 2456-2458

Prerequisites:
- AWS Account
- S3 bucket in which to store world backups (and terraform state)
- AWS credentials stored as the default profile (get credentials and then use `aws configure`)
- terraform (`brew install terraform`)
- awscli (`brew install awscli`)
- awscli session manager plugin (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- jq (`brew install jq`)

# How to deploy
# -------------
- Prepare
  - Create a new S3 bucket in your account
    - create a folder in the bucket called latest
    - copy your valheim world data from your local computer to this folder in your s3 bucket (files will have a `.db` and `.fwl` extension)
- Build cloud resources
  - `terraform init; terraform plan` will show you what will be created 
  - `terraform init; terraform apply` will deploy everything after typing yes
- Connect to server (for debugging):
  - `aws ssm start-session --target $(terraform output -json | jq -r '."instance-id".value')` will start and AWS SSM session to log into the server.
    - you need to have the awscli installed as well as the aws ssm session plugin
    - Useful commands:
      - `tail -f /var/log/cloud-init-output.log` to debug the `userdata.sh`
      - `systemctl status valheim` to see the valheim service status
      - `journalctl --unit valheim` to see the valheim server logslogs
  



<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.session_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.session_manger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.session_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.session_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [template_file.userdata](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | This is the size of your server (t2.micro: 1 cpu, 2GB ram, this is free tier; t3a.medium, 2 cpu, 4GB ram, not sure why I used this) | `string` | `"t2.micro"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | This is the s3 bucket you will be using to store your world files in. | `any` | n/a | yes |
| <a name="input_server_name"></a> [server\_name](#input\_server\_name) | This doesn't matter much. If you're server is public, this will be shown in the list of community servers. | `string` | `"MyServer"` | no |
| <a name="input_server_password"></a> [server\_password](#input\_server\_password) | This is the password users will enter after they put in the IP address of the server. | `any` | n/a | yes |
| <a name="input_world_name"></a> [world\_name](#input\_world\_name) | `world_name` must be the same name as your world files (ex: `world_name = "myworld"` would correlate with myworld.db and myworld.fwl). | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance-id"></a> [instance-id](#output\_instance-id) | ======= outputs ======= |
| <a name="output_public-ip"></a> [public-ip](#output\_public-ip) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
