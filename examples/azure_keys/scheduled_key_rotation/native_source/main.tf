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
  rotation_name   = "TestAzure-${lower(random_id.random.hex)}"
  connection_name = "TestAzure-${lower(random_id.random.hex)}"
  key_name        = "TestAzure-${lower(random_id.random.hex)}"
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
  subscription_id  = data.ciphertrust_azure_account_details.subscriptions.subscription_id
  name             = var.standard_vault_name
}

resource "ciphertrust_scheduler" "rotation_job" {
  end_date = "2022-03-07T14:00:00Z"
  key_rotation_params {
    cloud_name = "AzureCloud"
    expiration = "32d"
  }
  name       = local.rotation_name
  operation  = "cckm_key_rotation"
  run_at     = "0 9 * * sat"
  run_on     = "any"
  start_date = "2021-03-07T14:00:00Z"
}

# Create an EC key with scheduled rotation
# The new key will be sourced from Azure
# EC keys must be source from Azure
resource "ciphertrust_azure_key" "azure_key" {
  curve = "P-521"
  enable_rotation {
    job_config_id = ciphertrust_scheduler.rotation_job.id
    key_source    = "native"
  }
  key_ops  = ["sign", "verify"]
  key_type = "EC"
  name     = local.key_name
  vault    = ciphertrust_azure_vault.standard_vault.id
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}
