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
  connection_name = "TestHsm-${lower(random_id.random.hex)}"
  key_name        = "TestHsm-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

# Create a hsm network server
resource "ciphertrust_hsm_server" "hsm_server" {
  description     = "Description of the HSM network server"
  hostname        = var.hsm_hostname
  hsm_certificate = var.hsm_certificate
  meta            = "Some information to store with the HSM network server"
}

# Add create a hsm connection
resource "ciphertrust_hsm_connection" "hsm_connection" {
  description = "Description of the HSM connection"
  hostname    = var.hsm_hostname
  server_id   = ciphertrust_hsm_server.hsm_server.id
  meta        = "Some information to store with HSM connection"
  name        = local.connection_name
  dynamic "partitions" {
    for_each = var.hsm_partitions
    iterator = p
    content {
      partition_label = p.value.partition_label
      serial_number   = p.value.serial_number
    }
  }
  partition_password = var.hsm_partition_password
}
output "hsm_connection_id" {
  value = ciphertrust_hsm_connection.hsm_connection.id
}

# Add a partition to connection
resource "ciphertrust_hsm_partition" "hsm_partition" {
  hsm_connection = ciphertrust_hsm_connection.hsm_connection.id
}
output "hsm_partition_id" {
  value = ciphertrust_hsm_partition.hsm_partition.id
}

# Create a hsm key
resource "ciphertrust_hsm_key" "hsm_key" {
  attributes   = ["CKA_WRAP", "CKA_UNWRAP", "CKA_ENCRYPT", "CKA_DECRYPT"]
  label        = local.key_name
  mechanism    = "CKM_RSA_FIPS_186_3_AUX_PRIME_KEY_PAIR_GEN"
  partition_id = ciphertrust_hsm_partition.hsm_partition.id
  key_size     = 4096
}
output "hsm_key_id" {
  value = ciphertrust_hsm_key.hsm_key.id
}
