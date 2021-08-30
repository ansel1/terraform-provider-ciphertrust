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
  scheduled_rotation_name = "TestAws-${lower(random_id.random.hex)}"
  connection_name         = "TestAws-${lower(random_id.random.hex)}"
  kms_name                = "TestAws-${lower(random_id.random.hex)}"
  alias                   = "TestAws-${lower(random_id.random.hex)}"
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

# Create scheduled rotation job to run every Saturday at 9 am
resource "ciphertrust_scheduler" "scheduled_rotation_job" {
  end_date = "2022-03-07T14:24:00Z"
  key_rotation_params {
    cloud_name       = "aws"
    expiration       = "2d"
    aws_retain_alias = true
  }
  name       = local.scheduled_rotation_name
  operation  = "cckm_key_rotation"
  run_at     = "0 9 * * sat"
  run_on     = "any"
  start_date = "2021-03-07T14:24:00Z"
}

# Create an AES AWS key and schedule it for rotation
# The new key will be sourced from CipherTrust
resource "ciphertrust_aws_key" "aws_key" {
  alias = [local.alias]
  enable_rotation {
    disable_encrypt = false
    job_config_id   = ciphertrust_scheduler.scheduled_rotation_job.id
    key_source      = "ciphertrust"
  }
  kms    = ciphertrust_aws_kms.kms.id
  origin = "AWS_KMS"
  region = ciphertrust_aws_kms.kms.regions[0]
}
output "key" {
  value = ciphertrust_aws_key.aws_key
}
