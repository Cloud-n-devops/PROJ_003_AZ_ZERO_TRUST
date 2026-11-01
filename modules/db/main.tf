# Look up your user account dynamically
# data "azuread_user" "db_admin" {
#   user_principal_name = var.admin_user_email
# }
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-laravel-${var.project_name}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  
  # EXPERT SETTING: Total public lockdown
  public_network_access_enabled = false 

  azuread_administrator {
    login_username = "SqlAdmin"
    object_id      = "2de0bb57-4820-46d6-9ad5-e03c38bcb48a" # Your Entra User ID
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_database" "db_prod" {
  name      = "laravel_prod"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"
}
resource "azurerm_mssql_database" "db_staging" {
  name      = "laravel_staging"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"
}

# Private Endpoint (The DB's 'Internal NIC')
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "pe-sql-laravel"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "sql-privatelink"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
  # THE MISSING PIECE: This automatically creates the A Record
  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns.id]
  }
  depends_on = [azurerm_private_dns_zone.sql_dns]

}

# Private DNS Zone (Ensures the URL resolves to the Internal IP)
resource "azurerm_private_dns_zone" "sql_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "sql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
  virtual_network_id    = var.vnet_id
}