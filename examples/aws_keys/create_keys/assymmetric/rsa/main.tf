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
  connection_name   = "TestAws-${lower(random_id.random.hex)}"
  kms_name          = "TestAws-${lower(random_id.random.hex)}"
  rsa_key_alias_ex1 = "TestAws-ex1-${lower(random_id.random.hex)}"
  rsa_key_alias_ex2 = "TestAws-ex2-${lower(random_id.random.hex)}"
  extra_alias_2     = "TestAws-2-${lower(random_id.random.hex)}"
  extra_alias_3     = "TestAws-3-${lower(random_id.random.hex)}"
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
# Maximum use of input parameters for an RSA key
#
resource "ciphertrust_aws_key" "rsa_key_ex1" {
  alias                              = [local.rsa_key_alias_ex1, local.extra_alias_2, local.extra_alias_3]
  auto_rotate                        = false
  bypass_policy_lockout_safety_check = true
  description                        = "terraform create rsa key example"
  enable_key                         = false
  kms                                = ciphertrust_aws_kms.kms.id
  customer_master_key_spec           = "RSA_4096"
  key_usage                          = "SIGN_VERIFY"
  tags = {
    TagKey = "TagValue"
  }
  # To add key_policy edit policy_vars.tf and uncomment this block
  #key_policy {
  #  key_admins = [var.policy_admin]
  #  key_users  = [var.policy_user]
  #}
  region                     = ciphertrust_aws_kms.kms.regions[0]
  schedule_for_deletion_days = 14
}
output "rsa_key_ex1" {
  value = ciphertrust_aws_key.rsa_key_ex1
}

#
# Minumum use of input parameters for an RSA key
#
resource "ciphertrust_aws_key" "rsa_key_ex2" {
  alias                    = [local.rsa_key_alias_ex2]
  customer_master_key_spec = "RSA_3072"
  kms                      = ciphertrust_aws_kms.kms.id
  region                   = ciphertrust_aws_kms.kms.regions[0]
}
output "rsa_key_ex2" {
  value = ciphertrust_aws_key.rsa_key_ex2
}