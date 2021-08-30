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
  connection_name     = "TestAzure-${lower(random_id.random.hex)}"
  dsm_connection_name = "TestDsm-${lower(random_id.random.hex)}"
  key_name            = "TestAzure-${lower(random_id.random.hex)}"
  rotation_job_name   = "TestAzure-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

resource "ciphertrust_azure_connection" "connection" {
  name = local.connection_name
}

data "ciphertrust_azure_account_details" "subscriptions" {
  azure_connection = ciphertrust_azure_connection.connection.name
}

resource "ciphertrust_azure_vault" "standard_vault" {
  azure_connection = ciphertrust_azure_connection.connection.name
  name             = var.standard_vault_name
  subscription_id  = data.ciphertrust_azure_account_details.subscriptions.subscription_id
}

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

resource "ciphertrust_scheduler" "rotation_job" {
  end_date = "2022-03-07T14:00:00Z"
  key_rotation_params {
    cloud_name = "AzureCloud"
    expiration = "32d"
  }
  name       = local.rotation_job_name
  operation  = "cckm_key_rotation"
  run_at     = "0 9 * * sat"
  run_on     = "any"
  start_date = "2021-03-07T14:00:00Z"
}

# Create an RSA key with scheduled rotation
# The new key will be sourced from the dsm
resource "ciphertrust_azure_key" "azure_key" {
  enable_rotation {
    dsm_domain_id = ciphertrust_dsm_domain.dsm_domain_ex1.id
    job_config_id = ciphertrust_scheduler.rotation_job.id
    key_source    = "dsm"
  }
  key_type = "RSA"
  name     = local.key_name
  vault    = ciphertrust_azure_vault.standard_vault.id
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}
