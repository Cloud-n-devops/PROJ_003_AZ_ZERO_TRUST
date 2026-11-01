output "key_vault_secret_id_appkey" { 
  value = azurerm_key_vault_secret.app_key.versionless_id
  description = "base64::appkey"
}

output "key_vault_secret_id_app_url" { 
  value = azurerm_key_vault_secret.app_url.versionless_id
  description = "The secret ID of the App URL in Key Vault (without version, for use in App Service configuration)"
}
# output "random_password_db_admin_pass" { # return the generated password for use in db module
#   value = random_password.db_admin_pass.result
#   sensitive = true
# }
output "key_vault_id" {
  value = azurerm_key_vault.vault.id
}
output "managed_identity_github_client_id" {
  value = azurerm_user_assigned_identity.github_actions.client_id
}
output "key_vault_secret_id_db_host_write" { 
  value = azurerm_key_vault_secret.db_host_write.versionless_id
}
output "key_vault_secret_id_db_host_read" { 
  value = azurerm_key_vault_secret.db_host_read.versionless_id
}
output "waf_policy_id" {
  value = azurerm_web_application_firewall_policy.laravel_waf.id
}
