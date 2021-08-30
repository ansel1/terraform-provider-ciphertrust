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
  connection_name     = "TestAws-${lower(random_id.random.hex)}"
  dsm_connection_name = "TestDsm-${lower(random_id.random.hex)}"
  dsm_key_name        = "TestDsm-${lower(random_id.random.hex)}"
  kms_name            = "TestAws-${lower(random_id.random.hex)}"
  alias               = "TestAws-${lower(random_id.random.hex)}"
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

# Create a dsm connection
resource "ciphertrust_dsm_connection" "dsm_connection" {
  name = local.dsm_connection_name
  nodes {
    hostname    = var.dsm_ip
    certificate = var.dsm_certificate
  }
  password = var.dsm_password
  username = var.dsm_username
}

resource "ciphertrust_dsm_domain" "dsm_domain_ex1" {
  dsm_connection = ciphertrust_dsm_connection.dsm_connection.id
  domain_id      = var.dsm_domain_id_ex1
}

# Create a dsm AES key to upload to AWS
resource "ciphertrust_dsm_key" "dsm_key" {
  name            = local.dsm_key_name
  algorithm       = "AES256"
  domain          = ciphertrust_dsm_domain.dsm_domain_ex1.id
  encryption_mode = "CBC"
  expiration_date = "2022-03-07T21:24:52.001Z"
  extractable     = true
  object_type     = "symmetric"
}

# Upload the dsm key to AWS
resource "ciphertrust_aws_key" "aws_key" {
  alias  = [local.alias]
  kms    = ciphertrust_aws_kms.kms.id
  region = ciphertrust_aws_kms.kms.regions[0]
  upload_key {
    source_key_identifier = ciphertrust_dsm_key.dsm_key.id
    source_key_tier       = "dsm"
    valid_to              = "2022-03-07T00:00:00Z"
  }
}
output "key" {
  value = ciphertrust_aws_key.aws_key
}
