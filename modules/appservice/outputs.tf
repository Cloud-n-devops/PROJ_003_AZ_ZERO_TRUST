# The URL of your Laravel Website
output "webapp_url" {
  value       = "https://${azurerm_linux_web_app.Webapp_Laravel.default_hostname}"
  description = "The public URL of the Laravel App"
}
# Output for the Staging URL
output "webapp_url_staging" {
  value       = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
  description = "The URL of the staging deployment slot"
}
output "web_app_id" {
  value = azurerm_linux_web_app.Webapp_Laravel.id
}
output "app_service_principal_id" { 
  value = azurerm_linux_web_app.Webapp_Laravel.identity[0].principal_id
}
output "slot_principal_id" { 
  value = azurerm_linux_web_app_slot.staging.identity[0].principal_id
}
# output "slot_name" { 
#   value = azurerm_linux_web_app_slot.staging.name
# }