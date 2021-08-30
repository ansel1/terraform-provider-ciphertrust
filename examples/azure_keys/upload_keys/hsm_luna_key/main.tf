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
  hsm_connection_name = "TestHsm-${lower(random_id.random.hex)}"
  hsm_key_name        = "TestHsm-${lower(random_id.random.hex)}"
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
  dynamic "partitions" {
    for_each = var.hsm_partitions
    iterator = p
    content {
      partition_label = p.value.partition_label
      serial_number   = p.value.serial_number
    }
  }
  name               = local.hsm_connection_name
  partition_password = var.hsm_partition_password
  server_id          = ciphertrust_hsm_server.hsm_server.id
}

resource "ciphertrust_hsm_partition" "hsm_partition" {
  hsm_connection = ciphertrust_hsm_connection.hsm_connection.id
}

# Create a hsm key
resource "ciphertrust_hsm_key" "hsm_key" {
  attributes   = ["CKA_WRAP", "CKA_UNWRAP", "CKA_ENCRYPT", "CKA_DECRYPT"]
  label        = local.hsm_key_name
  mechanism    = "CKM_RSA_FIPS_186_3_AUX_PRIME_KEY_PAIR_GEN"
  partition_id = ciphertrust_hsm_partition.hsm_partition.id
  key_size     = 2048
}

# Upload the hsm key to Azure
resource "ciphertrust_azure_key" "azure_key" {
  name = local.key_name
  upload_key {
    hsm_key_id      = ciphertrust_hsm_key.hsm_key.private_key_id
    source_key_tier = "hsm-luna"
  }
  vault = ciphertrust_azure_vault.standard_vault.id
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}
