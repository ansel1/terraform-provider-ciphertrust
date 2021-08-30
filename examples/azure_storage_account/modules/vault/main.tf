terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
}

data "ciphertrust_azure_account_details" "subscriptions" {
  azure_connection = var.connection_name
}

resource "ciphertrust_azure_vault" "vault" {
  azure_connection = var.connection_name
  name             = var.vault_name
  subscription_id  = data.ciphertrust_azure_account_details.subscriptions.subscription_id
}

output "azure_vault" {
  value = ciphertrust_azure_vault.vault
}
