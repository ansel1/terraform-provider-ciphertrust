terraform {
  required_providers {
    ciphertrust = {
      version = "1.0.0"
      source  = "thales.com/terraform/ciphertrust"
    }
  }
}

resource "ciphertrust_aws_connection" "aws_connection" {
  name = var.name
}
