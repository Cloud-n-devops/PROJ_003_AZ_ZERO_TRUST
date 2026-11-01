output "debug_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "debug_subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

# The URL of your Laravel Website
output "webapp_url" {
  value       = "${module.appservice.webapp_url}"
  description = "The public URL of the Laravel App"
}
# Output for the Staging URL
output "staging_url" {
  value       = "${module.appservice.webapp_url_staging}"
  description = "The URL of the staging deployment slot"
}

# 2. The Database Connection Host (FQDN)
output "db_host" {
  value       = module.db.db_host
  description = "Use this in MySQL Workbench or your .env file"
}
# output "key_vault_secret_id_db_password" {
#   value       = module.security.key_vault_secret_id_db_password
#   description = "Display secret ID of db password in Key Vault (for verification)"
# }

output "health_check_url" {
  value = "${module.appservice.webapp_url}/api/health"
}

output "resource_group_lock_status" {
  value = "Locked (CanNotDelete)"
}
output "github_managed_identity_client_id" {
  value = module.security.managed_identity_github_client_id
}
output "waf_gateway_ip" {
  value = module.network.public_ip_address
}
