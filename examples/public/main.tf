# This is basically bookkeeping for Terraform, we'll use the same s3 bucket as the one that keeps our world files
terraform {
  backend "s3" {
    bucket = ""                  # put your bucket name here
    key    = "terraform.tfstate" # leave this alone
    region = "us-east-1"         # pick the region closest to you ("us-east-1" for east coast, "us-west-2" for west coast)
  }
}

provider "aws" {
  profile = "default"   # use the `aws configure` command to add your aws_access_key_id, aws_secret_access_key
  region  = "us-east-1" # pick the region closest to you ("us-east-1" for east coast, "us-west-2" for west coast)
}

# if you want to commit this terraform to github
# simply change the `server_password` variable in the module below to `server_password = var.server_password`
# this will ensure that you type the password each time you terraform plan/apply
# variable "server_password" {}

module "valheim_server" {

  source = "https://github.com/jameshounshell/valheim_server?ref=master"

  s3_bucket_name = ""           # put your bucket name here
  world_name     = ""           # the name of your world file
  instance_type  = "t3a.medium" # if your aws account is brand new, a t2.micro is free tier and should cost zero dollars to run for an entire year.

  # password must be >5 characters and can't be in the servername
  server_password = ""

  providers = {
    aws = aws
  }
}

output "instance-id" {
  value = module.valheim_server.instance-id
}

output "public-ip" {
  value = module.valheim_server.public-ip
}