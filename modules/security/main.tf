data "azurerm_client_config" "current" {}
locals {
  final_url = var.custom_domain_enabled ? "https://${var.custom_domain_name}" : var.webapp_default_url
}

resource "azurerm_key_vault" "vault" {
  name                        = "kv-${var.project_name}-${var.environment}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
#   rbac_authorization_enabled = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false # Set to true for production-production

  sku_name = "standard"

  # Network rules: Only allow access from your VNet
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
    virtual_network_subnet_ids = [var.app_service_subnet_id]
  }
}

# Store your DB Password as a Secret
# resource "azurerm_key_vault_secret" "db_password" {
#   name         = "db-password"
#   value        = var.random_generated_db_admin_pass
#   key_vault_id = azurerm_key_vault.vault.id
#   depends_on = [ var.random_generated_db_admin_pass, azurerm_key_vault_access_policy.terraform_user]
# #   depends_on = [ random_password.db_admin_pass, azurerm_key_vault_access_policy.terraform_user ]
# }

resource "azurerm_key_vault_secret" "app_url" {
  name         = "app-url"
  value        = local.final_url
  key_vault_id = azurerm_key_vault.vault.id
  depends_on = [azurerm_key_vault_access_policy.terraform_user]
}

resource "azurerm_key_vault_secret" "db_host_write" {
  name         = "db-host-write"
  value        = var.db_host_write
  key_vault_id = azurerm_key_vault.vault.id
  depends_on = [azurerm_key_vault_access_policy.terraform_user]
}

resource "azurerm_key_vault_secret" "db_host_read" {
  name         = "db-host-read"
  value        = var.db_host_read
  key_vault_id = azurerm_key_vault.vault.id
  depends_on = [azurerm_key_vault_access_policy.terraform_user]
}

# resource "azurerm_role_assignment" "app_to_kv" {
#   scope                = azurerm_key_vault.vault.id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = var.app_service_principal_id
# }
# resource "azurerm_role_assignment" "staging_app_to_kv" {
#   scope                = azurerm_key_vault.vault.id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = var.slot_principal_id
# }

# Give yourself access to the Key Vault (so you can see the secret in the portal and use it in CLI)
resource "azurerm_key_vault_access_policy" "terraform_user" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id #

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Purge", "Recover"
  ]
}

# modules/security/main.tf

resource "azurerm_key_vault_access_policy" "app_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.laravel_user_managed_principal_id
  depends_on = [azurerm_key_vault_access_policy.terraform_user]

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Storing the Laravel APP_KEY safely
resource "azurerm_key_vault_secret" "app_key" {
  name         = "laravel-app-key"
  value        = var.app_key
  key_vault_id = azurerm_key_vault.vault.id
  depends_on = [azurerm_key_vault_access_policy.terraform_user]
}

# Modern Terraform best practices recommend using Role Assignments with RBAC instead of Access Policies for Key Vault, especially when using System Assigned Identities. The above code reflects this approach by assigning the "Key Vault Secrets User" role to the App Service's managed identity, allowing it to read secrets from the Key Vault without needing explicit access policies.
# resource "azurerm_role_assignment" "terraform_to_kv" {
#   scope                = azurerm_key_vault.vault.id
#   role_definition_name = "Key Vault Secrets Officer" # "Officer" allows Get, List, and Set
#   principal_id         = data.azurerm_client_config.current.object_id
# }





# Github OIDC Federation for CI/CD (Optional but recommended for secure deployments without long-lived credentials)
# 1. The Identity GitHub will "wear"
resource "azurerm_user_assigned_identity" "github_actions" {
  name                = "id-github-actions-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# 2. The Trust Relationship (The OIDC Link)
resource "azurerm_federated_identity_credential" "github_oidc" {
  name                = "fed-github-oidc"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id           = azurerm_user_assigned_identity.github_actions.id
  
  # CRITICAL: This limits access to ONLY your repo and a specific branch
  subject             = "repo:kevohmwach/MSI-elara-laravel:ref:refs/heads/main"
}

# Specofically for slot swap with env. variable production
resource "azurerm_federated_identity_credential" "github_oidc_production" {
  name      = "fed-github-production"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_actions.id 
  
  audience  = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"
  
  # MUST match your Line 16 exactly
  subject   = "repo:kevohmwach/MSI-elara-laravel:environment:Production"
}

# 3. Grant the Identity "Contributor" access to the Resource Group
resource "azurerm_role_assignment" "github_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github_actions.principal_id
}

# Grant gtw user id access to the key vault
resource "azurerm_key_vault_access_policy" "appgw_kv_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.gtw_managed_user_principal_id

  secret_permissions = ["Get"]
}


# #WAF
resource "azurerm_web_application_firewall_policy" "laravel_waf" {
  name                = "waf-laravel-prod"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled       = true
    mode          = "Prevention" # Block traffic, don't just log it
    request_body_check = true
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}
