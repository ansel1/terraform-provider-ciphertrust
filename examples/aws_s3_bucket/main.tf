terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "3.37.0"
    }
  }
  required_version = ">= 0.12.26"
}

provider "ciphertrust" {}

resource "random_id" "random" {
  byte_length = 8
}

locals {
  connection_name = "TestAws-${lower(random_id.random.hex)}"
  kms_name        = "TestAws-${lower(random_id.random.hex)}"
  bucket_name     = "test-bucket-${lower(random_id.random.hex)}"
  key_name        = "TestAws-${lower(random_id.random.hex)}"
}

module "ciphertrust_aws_connection" {
  source = "./modules/connection"
  name   = local.connection_name
}

module "ciphertrust_aws_kms" {
  source     = "./modules/kms"
  connection = module.ciphertrust_aws_connection.connection
  name       = local.kms_name
}

module "ciphertrust_aws_key" {
  source = "./modules/key"
  kms    = module.ciphertrust_aws_kms.kms
  name   = local.key_name
  region = module.ciphertrust_aws_kms.kms_regions[0]
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = local.bucket_name
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = module.ciphertrust_aws_key.arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }
}