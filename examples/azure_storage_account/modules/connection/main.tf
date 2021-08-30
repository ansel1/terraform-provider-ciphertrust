terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
}

resource "ciphertrust_azure_connection" "connection" {
  name = var.name
}
