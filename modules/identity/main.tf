# User-Assigned Managed Identity
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "id-webapp-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
}
# resource "azurerm_role_assignment" "sql_identity_link" {
#   scope                = var.mssql_server_id
#   role_definition_name = "Reader" # Minimum permission to see the resource
#   principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
# }

# Create a User Assigned Identity for the Gateway
resource "azurerm_user_assigned_identity" "appgw_id" {
  name                = "id-appgw-secure"
  resource_group_name = var.resource_group_name
  location            = var.location
}
