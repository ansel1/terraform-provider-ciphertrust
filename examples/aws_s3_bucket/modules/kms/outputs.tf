output "kms_arn" {
  value = ciphertrust_aws_kms.aws_kms.arn
}
output "kms" {
  value = ciphertrust_aws_kms.aws_kms.id
}
output "kms_name" {
  value = ciphertrust_aws_kms.aws_kms.name
}
output "kms_regions" {
  value = ciphertrust_aws_kms.aws_kms.regions
}
