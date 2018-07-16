variable "aws_account_name" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "service_name" {
  type        = "string"
  description = "Name of Service"
  default     = "WebApp"
}

provider "vault" {}

data "vault_aws_access_credentials" "creds" {
  backend = "aws-${var.aws_account_name}"
  role    = "ec2_admin"
}

provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${data.vault_aws_access_credentials.creds.access_key}"
  secret_key = "${data.vault_aws_access_credentials.creds.secret_key}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  tags {
    Name = "${var.service_name}"
  }
}
