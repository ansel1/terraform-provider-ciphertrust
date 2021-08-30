output "arn" {
  value = module.ciphertrust_aws_key.arn
}
output "bucket_domain_name" {
  value = aws_s3_bucket.test_bucket.bucket_domain_name
}
output "key_id" {
  value = module.ciphertrust_aws_key.key_id
}

