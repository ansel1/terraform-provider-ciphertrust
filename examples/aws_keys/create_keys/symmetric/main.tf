terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
  required_version = ">= 0.12.26"
}

resource "random_id" "key_name" {
  byte_length = 8
}

locals {
  connection_name = "TestAws-${lower(random_id.key_name.hex)}"
  kms_name        = "TestAws-${lower(random_id.key_name.hex)}"
  alias_ex1       = "TestAws-ex1-${lower(random_id.key_name.hex)}"
  alias_ex2       = "TestAws-ex2-${lower(random_id.key_name.hex)}"
  extra_alias_2   = "TestAws-2-${lower(random_id.key_name.hex)}"
  extra_alias_3   = "TestAws-3-${lower(random_id.key_name.hex)}"
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

#
# Maximum use of input parameters for a symmetric key
#
resource "ciphertrust_aws_key" "sym_key_ex1" {
  alias                              = [local.alias_ex1, local.extra_alias_2, local.extra_alias_3]
  auto_rotate                        = true
  bypass_policy_lockout_safety_check = false
  enable_key                         = true
  kms                                = ciphertrust_aws_kms.kms.id
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  tags = {
    TagKey = "TagValue"
  }
  key_policy {
    policy = var.policy
  }
  region                     = ciphertrust_aws_kms.kms.regions[0]
  schedule_for_deletion_days = 10
}
output "sym_key_ex1" {
  value = ciphertrust_aws_key.sym_key_ex1
}

#
# Minimum use of input parameters for a symmetric key
#
resource "ciphertrust_aws_key" "sym_key_ex2" {
  alias  = [local.alias_ex2]
  kms    = ciphertrust_aws_kms.kms.id
  region = ciphertrust_aws_kms.kms.regions[0]
}
output "sym_key_ex2" {
  value = ciphertrust_aws_key.sym_key_ex2
}
