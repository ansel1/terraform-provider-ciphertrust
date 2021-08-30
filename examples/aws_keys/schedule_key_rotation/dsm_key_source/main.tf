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
  rotator_name        = "TestAws-${lower(random_id.random.hex)}"
  connection_name     = "TestAws-${lower(random_id.random.hex)}"
  dsm_connection_name = "TestDsm-${lower(random_id.random.hex)}"
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

# Create scheduled rotation job to run at 11 pm every day
resource "ciphertrust_scheduler" "rotation_job" {
  end_date = "2022-03-07T14:24:00Z"
  key_rotation_params {
    cloud_name = "aws"
    expiration = "2d"
  }
  name       = local.rotator_name
  operation  = "cckm_key_rotation"
  run_at     = "0 23 * * *"
  run_on     = "any"
  start_date = "2021-03-07T14:24:00Z"
}

# Create a dsm connection to use for rotation
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

# Create an AES AWS key and schedule it for rotation
# The new key will be sourced from the dsm
resource "ciphertrust_aws_key" "aws_key" {
  alias = [local.alias]
  enable_rotation {
    disable_encrypt = true
    dsm_domain_id   = ciphertrust_dsm_domain.dsm_domain_ex1.id
    job_config_id   = ciphertrust_scheduler.rotation_job.id
    key_source      = "dsm"
  }
  kms    = ciphertrust_aws_kms.kms.id
  origin = "AWS_KMS"
  region = ciphertrust_aws_kms.kms.regions[0]
}
output "key" {
  value = ciphertrust_aws_key.aws_key
}
