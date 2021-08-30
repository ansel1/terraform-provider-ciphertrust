terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
  required_version = ">= 0.12.26"
}

variable "premium_vault_name" {
  type    = string
  default = "cckm-test-premium-new"
}

resource "random_id" "random" {
  byte_length = 8
}

locals {
  connection_name = "TestAzure-${lower(random_id.random.hex)}"
  key_name        = "TestAzure-ec-hsm-key-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

resource "ciphertrust_azure_connection" "connection" {
  name = local.connection_name
}

data "ciphertrust_azure_account_details" "subscriptions" {
  azure_connection = ciphertrust_azure_connection.connection.name
}

resource "ciphertrust_azure_vault" "premium_vault" {
  azure_connection = ciphertrust_azure_connection.connection.name
  subscription_id  = data.ciphertrust_azure_account_details.subscriptions.subscription_id
  name             = var.premium_vault_name
}


#
# Create a hsm backed key in a premium vault
#
resource "ciphertrust_azure_key" "azure_key" {
  key_type = "RSA-HSM"
  name     = local.key_name
  vault    = ciphertrust_azure_vault.premium_vault.id
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}
