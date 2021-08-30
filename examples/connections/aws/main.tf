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
  key_name        = "TestAws-${lower(random_id.random.hex)}"
}

provider "ciphertrust" {}

# Create an AWS connection
resource "ciphertrust_aws_connection" "connection" {
  description = "Description of the AWS connection"
  name        = local.connection_name
  meta        = "Some information to store with the AWS connection"
}
output "aws_connection_id" {
  value = ciphertrust_aws_connection.connection.id
}

# Get the AWS account details
data "ciphertrust_aws_account_details" "account_details" {
  aws_connection = ciphertrust_aws_connection.connection.id
}

# Create a kms
resource "ciphertrust_aws_kms" "kms" {
  account_id     = data.ciphertrust_aws_account_details.account_details.account_id
  aws_connection = ciphertrust_aws_connection.connection.id
  name           = local.kms_name
  regions = [
    data.ciphertrust_aws_account_details.account_details.regions[0],
    data.ciphertrust_aws_account_details.account_details.regions[1],
  ]
}
output "aws_kms_id" {
  value = ciphertrust_aws_kms.kms.id
}

# Create a 2048 bit RSA key in AWS
resource "ciphertrust_aws_key" "aws_key" {
  alias                    = [local.key_name]
  customer_master_key_spec = "RSA_2048"
  kms                      = ciphertrust_aws_kms.kms.id
  key_usage                = "ENCRYPT_DECRYPT"
  region                   = data.ciphertrust_aws_account_details.account_details.regions[0]
  tags = {
    TagKey1 = "TagValue1"
    TagKey2 = "TagValue2"
  }
}
output "aws_key_id" {
  value = ciphertrust_aws_key.aws_key.id
}
output "aws_key_alias" {
  value = ciphertrust_aws_key.aws_key.alias
}
output "aws_key_key_id" {
  value = ciphertrust_aws_key.aws_key.key_id
}

