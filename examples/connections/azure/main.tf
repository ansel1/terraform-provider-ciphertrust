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

# Create an azure connection
resource "ciphertrust_azure_connection" "connection" {
  description = "Description of the Azure connection"
  name        = local.connection_name
  meta        = "Some information to store with the Azure connection"
}
output "azure_connection_id" {
  value = ciphertrust_azure_connection.connection.id
}

# Get Azure subscription
data "ciphertrust_azure_account_details" "subscriptions" {
  azure_connection = ciphertrust_azure_connection.connection.name
}

# Add a standard vault
resource "ciphertrust_azure_vault" "standard_vault" {
  azure_connection = ciphertrust_azure_connection.connection.name
  subscription_id  = data.ciphertrust_azure_account_details.subscriptions.subscription_id
  name             = var.standard_vault_name
}
output "standard_vault_id" {
  value = ciphertrust_azure_vault.standard_vault.id
}
output "standard_vault_name" {
  value = ciphertrust_azure_vault.standard_vault.name
}

# Create a 256 bit RSA key
resource "ciphertrust_azure_key" "azure_key" {
  name     = local.key_name
  key_type = "RSA"
  tags = {
    TagKey1 = "TagValue1"
    TagKey2 = "TagValue2"
  }
  vault = ciphertrust_azure_vault.standard_vault.id
}
output "azure_key_id" {
  value = ciphertrust_azure_key.azure_key.id
}
output "azure_key_key_id" {
  value = ciphertrust_azure_key.azure_key.key_id
}
