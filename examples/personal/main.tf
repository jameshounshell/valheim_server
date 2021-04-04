# This is basically bookkeeping for Terraform, we'll use the same s3 bucket as the one that keeps our world files
terraform {
  backend "s3" {
    bucket = "jah-valheim"       # put your bucket name here
    key    = "terraform.tfstate" # leave this alone
    region = "us-east-1"         # pick the region closest to you ("us-east-1" for east coast, "us-west-2" for west coast)
  }
}

provider "aws" {
  profile = "default"   # use the `aws configure` command to add your aws_access_key_id, aws_secret_access_key
  region  = "us-east-1" # pick the region closest to you ("us-east-1" for east coast, "us-west-2" for west coast)
}

# leaving blank to requires input each time, since this is on github
# you can delete this and enter the password in the module below if you don't plan to put this in github
variable "server_password" {}

module "valheim_server" {

  # delete this line and replace it with the commented one below
  source = "../../."

  # uncomment this line
  # source = "https://github.com/jameshounshell/valheim_server?ref=master"

  s3_bucket_name = "jah-valheim"
  world_name     = "SaltMine"   # the name of your world file
  instance_type  = "t3a.medium" # if your aws account is brand new, a t2.micro is free tier and should cost zero dollars to run for an entire year.

  server_password = "var.server_password"

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


# ======
# Extras
# ======
# optional, use if you have a domain name you want to use
# (valheim "join by ip" can now resolve dns, no more pesky remembering the server ip, just put in the dns name)
# I own jameshounshell.com so I'll use a custom subdomain "valheim."

data "aws_route53_zone" "jameshounshell_com" {
  name = "jameshounshell.com"
}
resource "aws_route53_record" "valheim_jameshounshell_com" {
  name    = "valheim.jameshounshell.com"
  type    = "A"
  zone_id = data.aws_route53_zone.jameshounshell_com.zone_id
}