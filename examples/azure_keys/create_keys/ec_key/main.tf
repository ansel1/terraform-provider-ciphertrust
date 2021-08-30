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
  ec_key_name_ex1 = "TestAzure-ex1-${lower(random_id.random.hex)}"
  ec_key_name_ex2 = "TestAzure-ex2-${lower(random_id.random.hex)}"
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

#
# Maximum use of input parameters for an EC key
#
resource "ciphertrust_azure_key" "ec_key_ex1" {
  activation_date = "2021-07-03T14:24:30Z"
  curve           = "SECP256K1"
  enable_key      = false
  expiration_date = "2022-07-03T14:24:30Z"
  key_ops         = ["sign", "verify"]
  key_type        = "EC"
  name            = local.ec_key_name_ex1
  tags = {
    TagKey1 = "TagValue1"
    TagKey2 = "TagValue2"
  }
  vault = ciphertrust_azure_vault.standard_vault.id
}
output "ec_key_ex1" {
  value = ciphertrust_azure_key.ec_key_ex1
}

#
# Minimum use of input parameters for an EC key
#
resource "ciphertrust_azure_key" "ec_key_ex2" {
  key_type = "EC"
  name     = local.ec_key_name_ex2
  vault    = ciphertrust_azure_vault.standard_vault.id
}
output "ec_key_ex2" {
  value = ciphertrust_azure_key.ec_key_ex2
}
