output "laravel_user_managed_id" {
  value = azurerm_user_assigned_identity.app_identity.id
}
output "gtw_managed_user_id" {
  value = azurerm_user_assigned_identity.appgw_id.id
}
output "laravel_user_managed_name" {
  value = azurerm_user_assigned_identity.app_identity.name
}
output "laravel_user_managed_principal_id" {
  value = azurerm_user_assigned_identity.app_identity.principal_id
}
output "laravel_user_managed_client_id" {
  value = azurerm_user_assigned_identity.app_identity.client_id
}
output "gtw_managed_user_principal_id" {
  value = azurerm_user_assigned_identity.appgw_id.principal_id
}


