terraform {
  required_providers {
    ciphertrust = {
      source  = "thales.com/terraform/ciphertrust"
      version = "1.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
  required_version = ">= 0.12.26"
}

# Azure key name has length restrictions
resource "random_id" "random" {
  byte_length = 6
}

locals {
  connection_name = "TestAzure-${lower(random_id.random.hex)}"
  key_name        = "TestAzure-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

module "ciphertrust_azure_connection" {
  source = "./modules/connection"
  name   = local.connection_name
}

# Create a storage account in the same resource group and location as the vault
resource "azurerm_storage_account" "storage-account" {
  name                     = "terraform${lower(random_id.random.hex)}"
  resource_group_name      = var.vault_resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  identity {
    type = "SystemAssigned"
  }
}

# Add an access policy to the vault for the storage account
resource "azurerm_key_vault_access_policy" "storage-account-policy" {
  key_vault_id       = module.ciphertrust_azure_vault.azure_vault_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_storage_account.storage-account.identity.0.principal_id
  key_permissions    = ["get", "create", "list", "restore", "recover", "unwrapkey", "wrapkey", "purge", "encrypt", "decrypt", "sign", "verify"]
  secret_permissions = ["get"]
}

# Add the vault to the connection
module "ciphertrust_azure_vault" {
  source          = "./modules/vault"
  connection_name = module.ciphertrust_azure_connection.connection_name
  vault_name      = var.vault_name
}

# Create a key
module "ciphertrust_azure_key" {
  source   = "./modules/key"
  key_name = local.key_name
  vault_id = module.ciphertrust_azure_vault.vault_id
  depends_on = [
    azurerm_key_vault_access_policy.storage-account-policy,
  ]
}

# Configure storage account to use the key
resource "azurerm_storage_account_customer_managed_key" "customer-managed-key" {
  storage_account_id = azurerm_storage_account.storage-account.id
  key_vault_id       = module.ciphertrust_azure_vault.azure_vault_id
  key_name           = module.ciphertrust_azure_key.key_name
  depends_on = [
    azurerm_key_vault_access_policy.storage-account-policy,
  ]
}
