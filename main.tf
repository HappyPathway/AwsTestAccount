variable "approle_role_id" {}

variable "approle_secret_id" {}

variable "aws_account_name" {}

variable "service_name" {
  type        = "string"
  description = "Name of Service"
  default     = "WebApp"
}

resource "vault_approle_auth_backend_role_login" "login" {
  backend   = "approle"
  role_id   = "${var.approle_role_id}"
  secret_id = "${var.approle_secret_id}"
}

provider "vault" {
  alias = "approle"
  token = "${vault_approle_auth_backend_role_login.login.client_token}"
}

data "vault_aws_access_credentials" "creds" {
  provider = "vault.approle"
  backend  = "aws-${var.aws_account_name}"
  role     = "ec2_admin"
}

provider "aws" {
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
