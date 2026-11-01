terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20" 
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}


provider "azurerm" {
  features {
    application_insights {
      # This prevents the "Failure Anomalies" rule and 
      # its Action Group from being created automatically.
      disable_generated_rule = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
   }
   key_vault {
      # This tells Terraform to permanently delete (purge) on destroy
      purge_soft_deleted_secrets_on_destroy = true
      purge_soft_deleted_keys_on_destroy    = true
      
      # If you want it to recover instead of failing if it finds a deleted vault
      recover_soft_deleted_key_vaults       = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "RG_app_service" {
    name = "app-service-rg"
    location = var.prod_location
}
# Generate a strong, random password
# resource "random_password" "db_admin_pass" {
#   length           = 20
#   special          = true
#   override_special = "!#$%&*()-_=+[]{}<>:?" # Avoid characters that break CLI strings
# }


# resource "azurerm_role_assignment" "app_to_kv" {
#   scope                = module.security.key_vault_id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = module.appservice.app_service_principal_id
# }
# resource "azurerm_role_assignment" "staging_app_to_kv" {
#   scope                = module.security.key_vault_id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = module.appservice.slot_principal_id
# }


# Assign sql managed user access to sql server
resource "azurerm_role_assignment" "sql_identity_link" {
  scope                = module.db.mssql_server_id
  role_definition_name = "Reader" # Minimum permission to see the resource
  principal_id         = module.identity.laravel_user_managed_principal_id
}

# Policy for the APP SERVICE
# resource "azurerm_key_vault_access_policy" "app_service" {
#   key_vault_id = module.security.key_vault_id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = module.identity.laravel_user_managed_principal_id

#   secret_permissions = ["Get", "List"]
# }

# # Policy for the STAGING SLOT - Not needed. Sharing same identity with the prod app
# resource "azurerm_key_vault_access_policy" "staging_slot" {
#   key_vault_id = module.security.key_vault_id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = module.appservice.slot_principal_id # Passed from app module

#   secret_permissions = ["Get", "List"]
# }


module "appservice" {
  source = "./modules/appservice"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  project_name        = var.project_name
  production_db_name = module.db.production_db_name
  staging_db_name = module.db.staging_db_name
  db_host = module.db.db_host
  # db_host = "laravel-db-server-flex.privatelink.mysql.database.azure.com"
  storage_account_name = module.storage.storage_account_name
  storage_account_accesskey = module.storage.storage_account_accesskey
  file_share_name = module.storage.file_share_name
  instrumentation_key = module.observability.instrumentation_key
  connection_string = module.observability.connection_string
  appservice_subnet_id = module.network.appservice_subnet_id
  appinsights_id = module.observability.appinsights_id
  # key_vault_secret_id_db_password = module.security.key_vault_secret_id_db_password
  custom_domain_name = var.custom_domain_name
  key_vault_secret_id_app_url = module.security.key_vault_secret_id_app_url
  key_vault_secret_id_appkey = module.security.key_vault_secret_id_appkey
  # kv_db_host_write = module.security.key_vault_secret_id_db_host_write
  # kv_db_host_read = module.security.key_vault_secret_id_db_host_read
  environment = var.environment
  laravel_user_managed_id = module.identity.laravel_user_managed_id
  laravel_user_managed_client_id = module.identity.laravel_user_managed_client_id
  laravel_user_managed_name = module.identity.laravel_user_managed_name
  waf_subnet_id = module.network.waf_subnet_id
  gtw_ip_address = module.network.public_ip_address
  prod_hostname = var.prod_hostname
  staging_hostname = var.staging_hostname
  laravel_credentials = {
    pat: {
        # github_pat: var.laravel_credentials.pat.github_pat
    }
    repo: {
        laravel_app_repo: var.laravel_credentials.repo.laravel_app_repo
    }
    branch: {
        laravel_app_branch: var.laravel_credentials.branch.laravel_app_branch
    }
    db: {
        # admin_user: var.laravel_credentials.db.admin_user, 
        # admin_pass: var.laravel_credentials.db.admin_pass
    },

    env:{
        # appkey = var.laravel_credentials.env.appkey
    },
}
  
}
module "gateway" {
  source = "./modules/gateway"
   resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  project_name        = var.project_name
  waf_policy_id = module.security.waf_policy_id
  waf_subnet_id = module.network.waf_subnet_id
  public_ip_id = module.network.public_ip_id
  environment = var.environment
  webapp_url = module.appservice.webapp_url
  webapp_url_staging = module.appservice.webapp_url_staging
  gtw_managed_user_id = module.identity.gtw_managed_user_id
  kv_ssl_cert_name = var.kv_ssl_cert_name
  key_vault_id = module.security.key_vault_id
  prod_hostname = var.prod_hostname
  staging_hostname = var.staging_hostname
  ssl_certificate_name = var.ssl_certificate_name
  # ssl_pfx_password = "gradestar123"
}
module "db" {
  source = "./modules/db"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  db_subnet_id = module.network.db_subnet_id
  # private_dns_zone_id = module.network.private_dns_zone_id
  # private_dns_vnet_link_id = module.network.private_dns_vnet_link_id
  # random_password_db_admin_pass = random_password.db_admin_pass.result
  vnet_id = module.network.vnet_id
  laravel_user_managed_object_id = module.identity.laravel_user_managed_principal_id
  pe_subnet_id = module.network.pe_subnet_id
  project_name = var.project_name
  admin_user_email = var.admin_user_email
  laravel_credentials = {
    db: {
        admin_user: var.laravel_credentials.db.admin_user, 
        admin_pass: var.laravel_credentials.db.admin_pass
    },
  }
  
}

module "network" {
  source = "./modules/network"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  addr_space = var.addr_space
  prod_subnet_prefixes = var.prod_subnet_prefixes
  db_subnet_prefixes = var.db_subnet_prefixes
  appservice_subnet_prefixes = var.appservice_subnet_prefixes
  pe_subnet_prefixes = var.pe_subnet_prefixes
  waf_subnet_prefix = var.waf_subnet_prefix
  # app_service_id = module.appservice.app_service_id
  # slot_name = module.appservice.slot_name
  
}
module "identity" {
  source = "./modules/identity"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location = azurerm_resource_group.RG_app_service.location
  project_name = var.project_name
  # mssql_server_id = module.db.mssql_server_id
}
module "storage" {
  source = "./modules/storage"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  db_subnet_id = module.network.db_subnet_id
  appservice_subnet_id = module.network.appservice_subnet_id
  
}
module "observability" {
  source = "./modules/observability"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  web_app_id = module.appservice.web_app_id
  alert_email         = var.email_address.kelvin
  db_server_id        = module.db.db_server_id
  production_db_id = module.db.production_db_id
  
}
module "security" {
  source = "./modules/security"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  # app_service_principal_id = module.appservice.app_service_principal_id
  # slot_principal_id = module.appservice.slot_principal_id
  project_name = var.project_name
  environment = var.environment
  db_password = var.laravel_credentials.db.admin_pass
  app_service_subnet_id = module.network.appservice_subnet_id  
  custom_domain_name = var.custom_domain_name
  webapp_default_url = var.webapp_default_url
  custom_domain_enabled = var.custom_domain_enabled
  resource_group_id = azurerm_resource_group.RG_app_service.id
  # random_generated_db_admin_pass = random_password.db_admin_pass.result
  db_host_write = module.db.db_host
  db_host_read = module.db.db_host
  laravel_user_managed_principal_id = module.identity.laravel_user_managed_principal_id
  app_key = var.laravel_credentials.env.appkey
  gtw_managed_user_principal_id = module.identity.gtw_managed_user_principal_id

}
module "governance" {
  source = "./modules/governance"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  resource_group_id = azurerm_resource_group.RG_app_service.id
  location            = azurerm_resource_group.RG_app_service.location
  db_server_id = module.db.db_server_id
  vnet_id = module.network.vnet_id
  project_name = var.project_name
  alert_email = var.email_address.kelvin
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  tenant_id = data.azurerm_client_config.current.tenant_id
}




