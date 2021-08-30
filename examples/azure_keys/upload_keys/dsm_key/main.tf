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
  dsm_connection_name = "TestDsm-${lower(random_id.random.hex)}"
  dsm_key_name        = "TestDsm-${lower(random_id.random.hex)}"
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

resource "ciphertrust_dsm_connection" "dsm_connection" {
  name = local.dsm_connection_name
  nodes {
    hostname    = var.dsm_ip
    certificate = var.dsm_certificate
  }
  password = var.dsm_password
  username = var.dsm_username
}

resource "ciphertrust_dsm_domain" "dsm_domain_ex1" {
  dsm_connection = ciphertrust_dsm_connection.dsm_connection.id
  domain_id      = var.dsm_domain_id_ex1
}

# Create a dsm RSA key
resource "ciphertrust_dsm_key" "dsm_key" {
  name            = local.dsm_key_name
  algorithm       = "RSA2048"
  domain          = ciphertrust_dsm_domain.dsm_domain_ex1.id
  expiration_date = "2022-03-07T21:24:52.001Z"
  extractable     = true
  object_type     = "asymmetric"
}

# Upload dsm key to Azure
resource "ciphertrust_azure_key" "azure_key" {
  name  = local.key_name
  vault = ciphertrust_azure_vault.standard_vault.id
  upload_key {
    dsm_key_id      = ciphertrust_dsm_key.dsm_key.id
    source_key_tier = "dsm"
  }
}
output "key" {
  value = ciphertrust_azure_key.azure_key
}
