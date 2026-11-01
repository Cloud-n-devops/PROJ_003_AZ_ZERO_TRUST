output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_accesskey" {
  value = azurerm_storage_account.storage_account.primary_access_key
}

output "file_share_name" {
  value = azurerm_storage_share.uploads.name
}