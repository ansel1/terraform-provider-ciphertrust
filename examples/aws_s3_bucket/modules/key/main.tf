terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
}

resource "ciphertrust_aws_key" "key" {
  alias = [var.name]
  kms   = var.kms
  import_key_material {
    source_key_name = var.name
    source_key_tier = "local"
  }
  region = var.region
  origin = "EXTERNAL"
}
