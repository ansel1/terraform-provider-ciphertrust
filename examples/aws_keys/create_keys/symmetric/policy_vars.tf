variable "policy" {
  type    = string
  default = <<-EOT
		{"Version":"2012-10-17","Id":"kms-tf-1","Statement":[{"Sid":"Enable IAM User Permissions 1","Effect":"Allow","Principal":{"AWS":"*"},"Action":"kms:*","Resource":"*"}]}
  EOT
}
