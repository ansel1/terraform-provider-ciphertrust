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
  connection_name = "TestAzure-${lower(random_id.random.hex)}"
  local_key_name  = "TestCCKM-${lower(random_id.random.hex)}"
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

resource "ciphertrust_cm_key" "local_key" {
  algorithm = "RSA"
  name      = local.local_key_name
  key_size  = 4096
}

# Default for source_key_tier is "local"
resource "ciphertrust_azure_key" "azure_key" {
  key_ops = ["encrypt", "decrypt"]
  name    = local.key_name
  vault   = ciphertrust_azure_vault.standard_vault.id
  upload_key {
    local_key_id = ciphertrust_cm_key.local_key.id
  }
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}
