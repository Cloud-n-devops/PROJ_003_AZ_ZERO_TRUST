# Implementing Persistent storage for Laravel (Azure Files)
resource "azurerm_storage_account" "storage_account" {
  name                     = "laravelfilestorage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"
}
# 2. The File Share (The Logical Partition)
resource "azurerm_storage_share" "uploads" {
  name                 = "laravel-uploads"
  storage_account_id = azurerm_storage_account.storage_account.id
  quota                = 50 # Limit to 50GB
}
# Lock down the STORAGE ACCOUNT Firewall
resource "azurerm_storage_account_network_rules" "lockdown" {
  storage_account_id = azurerm_storage_account.storage_account.id

  default_action             = "Allow" # BLOCK EVERYTHING ELSE
  virtual_network_subnet_ids = [var.appservice_subnet_id] # ALLOW ONLY THE APP
  # CRITICAL: This allows Azure's mounting infrastructure to talk to the share
  bypass = ["AzureServices"]
  
  # Optional: Allow your office IP so you can still see files in the portal
  # ip_rules = ["YOUR_OFFICE_IP"] 
}