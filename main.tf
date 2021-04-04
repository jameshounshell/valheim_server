/*
Terraform module to create a simple Valheim server in AWS

Requires:
- S3 bucket created in advance containing world files in s3://<your bucket>/latest

*/

provider "aws" {}

# =========
# variables
# =========
variable "server_name" {
  description = "This doesn't matter much. If you're server is public, this will be shown in the list of community servers."
  default     = "MyServer"
}

variable "world_name" {
  description = "`world_name` must be the same name as your world files (ex: `world_name = \"myworld\"` would correlate with myworld.db and myworld.fwl)."
}

variable "server_password" {
  description = "This is the password users will enter after they put in the IP address of the server."
}

variable "s3_bucket_name" {
  description = "This is the s3 bucket you will be using to store your world files in."
}

variable "instance_type" {
  description = "This is the size of your server (t2.micro: 1 cpu, 2GB ram, this is free tier; t3a.medium, 2 cpu, 4GB ram, not sure why I used this)"
  default     = "t2.micro"
}

# =======
# outputs
# =======
output "instance-id" {
  value = aws_instance.main.id
}

output "public-ip" {
  value = aws_instance.main.public_ip
}


# ====
# main
# ====
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*.0-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "main" {
  name = "valheim"
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 2456
  to_port           = 2458
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

data "template_file" "userdata" {
  template = "${path.module}/userdata.template.sh"
  vars = {
    WORLD_NAME      = var.world_name,
    SERVER_NAME     = var.server_name,
    SERVER_PASSWORD = var.server_password,
    S3_BUCKET_NAME  = var.s3_bucket_name
  }
}

resource "aws_instance" "main" {
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = "t3a.medium"
  iam_instance_profile = aws_iam_instance_profile.session_manager.name
  security_groups      = [aws_security_group.main.name]
  user_data            = data.template_file.userdata.rendered

  lifecycle {
    ignore_changes = [ami]
  }

}

# https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-create-iam-instance-profile.html
resource "aws_iam_policy" "session_manger" {
  name        = "session_manger"
  description = "session manager"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetEncryptionConfiguration"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "session_manager" {
  policy_arn = aws_iam_policy.session_manger.arn
  role       = aws_iam_role.session_manager.name
}

resource "aws_iam_role" "session_manager" {
  name = "session_manager"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "session_manager" {
  name = "session_manager"
  role = aws_iam_role.session_manager.name
}