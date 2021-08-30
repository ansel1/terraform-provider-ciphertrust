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
  connection_name = "TestAws-${lower(random_id.random.hex)}"
  kms_name        = "TestAws-${lower(random_id.random.hex)}"
  local_key_name  = "TestCCKM-${lower(random_id.random.hex)}"
  alias           = "TestAws-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

resource "ciphertrust_aws_connection" "connection" {
  name = local.connection_name
}

data "ciphertrust_aws_account_details" "account_details" {
  aws_connection = ciphertrust_aws_connection.connection.id
}

resource "ciphertrust_aws_kms" "kms" {
  account_id     = data.ciphertrust_aws_account_details.account_details.account_id
  aws_connection = ciphertrust_aws_connection.connection.id
  name           = local.kms_name
  regions        = [data.ciphertrust_aws_account_details.account_details.regions[0]]
}

# Create a CipherTrust key and an external AWS key
# Import the key material of the CipherTrust key to the AWS key
resource "ciphertrust_aws_key" "aws_key" {
  alias = [local.alias]
  import_key_material {
    source_key_name = local.local_key_name
    source_key_tier = "local"
  }
  kms    = ciphertrust_aws_kms.kms.id
  origin = "EXTERNAL"
  region = ciphertrust_aws_kms.kms.regions[0]
}
output "key" {
  value = ciphertrust_aws_key.aws_key
}
