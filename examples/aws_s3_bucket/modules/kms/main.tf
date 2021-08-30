terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
}

data "ciphertrust_aws_account_details" "account_details" {
  aws_connection = var.connection
}

resource "ciphertrust_aws_kms" "aws_kms" {
  account_id     = data.ciphertrust_aws_account_details.account_details.account_id
  aws_connection = var.connection
  name           = var.name
  regions        = data.ciphertrust_aws_account_details.account_details.regions
}
