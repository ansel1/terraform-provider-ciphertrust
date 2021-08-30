output "key_name" {
  value = module.ciphertrust_azure_key.key_name
}
output "storage_account_name" {
  value = azurerm_storage_account.storage-account.name
}

