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
  connection_name = "TestDsm-${lower(random_id.random.hex)}"
  rsa_key_name    = "TestDsm-Rsa-${lower(random_id.random.hex)}"
  aes_key_name    = "TestDsm-Aes-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

# Create a dsm connection
resource "ciphertrust_dsm_connection" "connection" {
  description = "Description of the DSM connection"
  name        = local.connection_name
  meta        = "Some information to store with the DSM connection"
  nodes {
    hostname    = var.dsm_ip
    certificate = var.dsm_certificate
  }
  password = var.dsm_password
  username = var.dsm_username
}
output "dsm_connection_id" {
  value = ciphertrust_dsm_connection.connection.id
}

# Add a dsm domain
resource "ciphertrust_dsm_domain" "dsm_domain_ex1" {
  description    = "Description of the DSM domain"
  dsm_connection = ciphertrust_dsm_connection.connection.id
  domain_id      = var.dsm_domain_1
}
output "dsm_domain_ex1_id" {
  value = ciphertrust_dsm_domain.dsm_domain_ex1.id
}

# Add another dsm domain
resource "ciphertrust_dsm_domain" "dsm_domain_ex2" {
  dsm_connection = ciphertrust_dsm_connection.connection.id
  domain_id      = var.dsm_domain_2
}
output "dsm_domain_ex2_id" {
  value = ciphertrust_dsm_domain.dsm_domain_ex2.id
}

# Create a dsm RSA key
resource "ciphertrust_dsm_key" "dsm_rsa_key" {
  algorithm       = "RSA2048"
  description     = "dsm rsa key"
  domain          = ciphertrust_dsm_domain.dsm_domain_ex1.id
  expiration_date = "2022-03-07T21:24:52.001Z"
  name            = local.rsa_key_name
  object_type     = "asymmetric"
}
output "dsm_rsa_key_id" {
  value = ciphertrust_dsm_key.dsm_rsa_key.id
}

# Create a dsm AES key
resource "ciphertrust_dsm_key" "dsm_aes_key" {
  algorithm       = "AES256"
  description     = "dsm aes key"
  domain          = ciphertrust_dsm_domain.dsm_domain_ex2.id
  encryption_mode = "CBC"
  expiration_date = "2022-03-07T21:24:52.001Z"
  extractable     = true
  name            = local.aes_key_name
  object_type     = "symmetric"
}
output "dsm_aes_key_id" {
  value = ciphertrust_dsm_key.dsm_aes_key.id
}
