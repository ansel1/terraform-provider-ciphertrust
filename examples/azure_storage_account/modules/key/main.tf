terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
}

# Create a CipherTrust key
resource "ciphertrust_azure_key" "key" {
  name     = var.key_name
  vault    = var.vault_id
  key_type = "RSA"
}

