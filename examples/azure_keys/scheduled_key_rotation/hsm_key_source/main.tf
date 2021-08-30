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
  rotation_name       = "TestAzure-${lower(random_id.random.hex)}"
  connection_name     = "TestAzure-${lower(random_id.random.hex)}"
  hsm_connection_name = "TestHsm-${lower(random_id.random.hex)}"
  key_name            = "TestAzure-${lower(random_id.random.hex)}"
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

resource "ciphertrust_hsm_server" "hsm_server" {
  hostname        = var.hsm_hostname
  hsm_certificate = var.hsm_certificate
}

resource "ciphertrust_hsm_connection" "hsm_connection" {
  is_ha_enabled = false
  hostname      = var.hsm_hostname
  server_id     = ciphertrust_hsm_server.hsm_server.id
  name          = local.hsm_connection_name
  dynamic "partitions" {
    for_each = var.hsm_partitions
    iterator = p
    content {
      partition_label = p.value.partition_label
      serial_number   = p.value.serial_number
    }
  }
  partition_password = var.hsm_partition_password
}

resource "ciphertrust_hsm_partition" "hsm_partition" {
  hsm_connection = ciphertrust_hsm_connection.hsm_connection.id
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

# Create an RSA key with scheduled rotation
# The new key will be sourced from the hsm
resource "ciphertrust_azure_key" "azure_key" {
  enable_rotation {
    hsm_partition_id = ciphertrust_hsm_partition.hsm_partition.id
    job_config_id    = ciphertrust_scheduler.rotation_job.id
    key_source       = "hsm-luna"
  }
  key_type = "RSA"
  name     = local.key_name
  key_size = 2048
  vault    = ciphertrust_azure_vault.standard_vault.id
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}
