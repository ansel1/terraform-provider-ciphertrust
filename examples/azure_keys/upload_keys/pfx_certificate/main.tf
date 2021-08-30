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

# Upload a pfx file to Azure
resource "ciphertrust_azure_key" "azure_key" {
  name = local.key_name
  upload_key {
    pfx             = var.pfx_file
    pfx_password    = var.pfx_pwd
    source_key_tier = "pfx"
  }
  vault = ciphertrust_azure_vault.standard_vault.id
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}