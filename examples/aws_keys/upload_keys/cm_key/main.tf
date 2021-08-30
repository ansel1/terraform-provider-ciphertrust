terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
  required_version = ">= 0.12.26"
}

resource "random_id" "random" {
  byte_length = 8
}

locals {
  connection_name = "TestAws-${lower(random_id.random.hex)}"
  kms_name        = "TestAws-${lower(random_id.random.hex)}"
  local_key_name  = "TestCCKM-${lower(random_id.random.hex)}"
  alias           = "TestAws-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

resource "ciphertrust_aws_connection" "connection" {
  name = local.connection_name
}

data "ciphertrust_aws_account_details" "account_details" {
  aws_connection = ciphertrust_aws_connection.connection.id
}

resource "ciphertrust_aws_kms" "kms" {
  account_id     = data.ciphertrust_aws_account_details.account_details.account_id
  aws_connection = ciphertrust_aws_connection.connection.id
  name           = local.kms_name
  regions        = data.ciphertrust_aws_account_details.account_details.regions
}

# Create an AES CipherTrust key to upload to AWS
resource "ciphertrust_cm_key" "local_key" {
  name      = local.local_key_name
  algorithm = "AES"
}

# Upload the CipherTrust key to a new AWS key
resource "ciphertrust_aws_key" "aws_key" {
  alias  = [local.alias]
  kms    = ciphertrust_aws_kms.kms.id
  region = ciphertrust_aws_kms.kms.regions[0]
  upload_key {
    key_expiration        = true
    source_key_identifier = ciphertrust_cm_key.local_key.id
    valid_to              = "2022-03-07T00:00:00Z"
  }
}
output "key" {
  value = ciphertrust_aws_key.aws_key
}
