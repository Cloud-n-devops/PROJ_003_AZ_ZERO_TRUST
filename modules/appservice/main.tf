locals {
  common_app_settings = {
    "APP_KEY" = "@Microsoft.KeyVault(SecretUri=${var.key_vault_secret_id_appkey})"
    "DB_CONNECTION" = "sqlsrv"
    "DB_AUTHENTICATION" = "ActiveDirectoryMsi"
    "DB_HOST" = var.db_host
    "DB_PORT" = "1433"
    # "DB_USERNAME" = var.laravel_user_managed_name
    "DB_USERNAME" = var.laravel_user_managed_client_id
    "DB_PASSWORD" = ""
    "DB_ENCRYPT" = "yes"
    "DB_TRUST_SERVER_CERTIFICATE" = false
    # "DB_HOST_WRITE" = "@Microsoft.KeyVault(SecretUri=${var.kv_db_host_write})"
    # "DB_HOST_READ" = "@Microsoft.KeyVault(SecretUri=${var.kv_db_host_read})"
    "MYSQL_ATTR_SSL_CA" = "/home/site/wwwroot/certs/DigiCertGlobalRootG2.crt.pem"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "APP_DEBUG"     = "true"
    "SESSION_DRIVER" = "database"
    "SESSION_LIFETIME" = "120"
    "SESSION_SECURE_COOKIE"=true
    "AZURE_CLIENT_ID"   = var.laravel_user_managed_client_id
    "ARM_CLIENT_ID" = var.laravel_user_managed_client_id
    # Tell Laravel that the Gateway is a trusted proxy
    "TRUSTED_PROXIES"="10.0.5.0/24"

    "LOG_STACK" = "single,insights"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    # Tells the app to use Azure's internal DNS resolver that sits inside your VNet
    "WEBSITE_DNS_SERVER"     = "168.63.129.16" 
  }
}

# Wait 30 seconds after the subnet is modified/created
resource "time_sleep" "wait_30_seconds" {
  depends_on = [var.appservice_subnet_id]
  create_duration = "30s"
}

resource "azurerm_service_plan" "app_service_plan_laravel" {
  name                = "laravel-appserviceplan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
#   sku_name            = "B1" 
  sku_name            = "S1" # Allow adding slots for staging/blue-green deployments
  # sku_name            = "P1v2" # Allow autoscaling 
}



resource "azurerm_linux_web_app" "Webapp_Laravel" {
  name                = "laravel-webapp-elora"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_service_plan_laravel.id
  public_network_access_enabled = true # Defaults to true
  # Force HTTPS only
  https_only = true


  # tags = {
  #   # This specific tag format tells the Azure Portal to show 
  #   # the Application Insights menu on the left sidebar.
  #   # "hidden-link:${var.appinsights_id}" = "Resource"
  # }

site_config {
    application_stack {
      php_version = "8.2"
    }
    ip_restriction {
      virtual_network_subnet_id = var.waf_subnet_id
      name                      = "Allow-Only-WAF-Subnet"
      priority                  = 100
      action                    = "Allow"
    }
    
    # Optional: Block all other traffic (Implicitly happens if any restriction exists)
    scm_use_main_ip_restriction = true

    app_command_line = "/home/site/wwwroot/appservice_files/startup-command.sh"
    vnet_route_all_enabled = true
    # If it returns 500 or times out, Azure removes the instance from the LB.
    health_check_path                 = "/api/health"
    # Valid values are between 2 and 10. 10 is the standard default for most SRE setups.
    health_check_eviction_time_in_min = 10

  
    minimum_tls_version = "1.2"
    # # HTTP2 for better performance
    # http2_enabled = true

    # ip_restriction {
    #   action                    = "Allow"
    #   virtual_network_subnet_id = var.
    #   name                      = "AllowTrafficFromAppGw"
    # }
    
  }

  app_settings = merge(local.common_app_settings, {
    "APP_ENV" = var.environment
    "APP_NAME" = "Elara on App Service - Laravel Sample"
    # "APP_URL"     = "@Microsoft.KeyVault(SecretUri=${var.key_vault_secret_id_app_url})"
    "APP_URL"     = "https://${var.prod_hostname}"
    "ASSET_URL"= "https://${var.prod_hostname}"
    "DB_DATABASE" = var.production_db_name
  })

  # CRITICAL: This makes the settings "Sticky"
  # Even if you SWAP, the Prod slot keeps 'production' values
  sticky_settings {
    app_setting_names = ["DB_DATABASE", "APP_ENV", "APP_NAME", "APP_URL", "DB_HOST", "WEBSITE_DNS_SERVER"]
  }

  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id, # vnet connection to be done as a resource of its own to control timing and dependencies
      tags["hidden-link: /app-insights-resource-id"], # Ignore ONLY this specific key
    ]
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.laravel_user_managed_id]
  }
  
  # CRITICAL: This tells the App Service to use the User Identity 
  # for the @Microsoft.KeyVault() references.
  key_vault_reference_identity_id = var.laravel_user_managed_id

  # Mount File share for persistent storage of uploads (simulate "local" disk in Laravel)
  storage_account {
    access_key   = var.storage_account_accesskey
    account_name = var.storage_account_name
    name         = "uploadsmount-${var.project_name}"
    share_name   = var.file_share_name
    type         = "AzureFiles"
    mount_path   = "/home/site/wwwroot/storage/app"
  }
  
}
# Link webapp to vnet for secure DB connectivity (Private Endpoint alternative)
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
  subnet_id      = var.appservice_subnet_id  # A different subnet in the same VNet
  depends_on = [time_sleep.wait_30_seconds] # Ensure the subnet is fully ready before connecting
}
# The Staging Slot (Child)
resource "azurerm_linux_web_app_slot" "staging" {
  name = "laravel-app-staging"
  app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
  # Force HTTPS only
  # https_only = true

  site_config {
    application_stack {
      php_version = "8.2"
    }
    ip_restriction {
      virtual_network_subnet_id = var.waf_subnet_id
      name                      = "Allow-Only-WAF-Subnet"
      priority                  = 100
      action                    = "Allow"
    }
    
    # Optional: Block all other traffic (Implicitly happens if any restriction exists)
    scm_use_main_ip_restriction = true

    app_command_line = "/home/site/wwwroot/appservice_files/startup-command.sh"
    vnet_route_all_enabled = true
    # If it returns 500 or times out, Azure removes the instance from the LB.
    health_check_path                 = "/api/health"
    health_check_eviction_time_in_min = 10
    
    # # Minimum TLS version (SRE Gold Standard is 1.2)
    # minimum_tls_version = "1.2"
  }
  app_settings = merge(local.common_app_settings, {
    "APP_ENV" = "Staging"
    "APP_NAME" = "Staging -Elara on App Service - Laravel Sample"
    # "APP_URL" = "https://laravel-webapp-elora-laravel-app-staging.azurewebsites.net"
    "APP_URL" = "https://${var.staging_hostname}"
    "ASSET_URL"= "https://${var.staging_hostname}"
    "DB_DATABASE" = var.staging_db_name
})

lifecycle {
    ignore_changes = [
      virtual_network_subnet_id, # vnet connection to be done as a resource of its own to control timing and dependencies
      tags["hidden-link: /app-insights-resource-id"], # Ignore ONLY this specific key
    ]
  }
 identity {
    type         = "UserAssigned"
    identity_ids = [var.laravel_user_managed_id]
  }
  # CRITICAL: This tells the App Service to use the User Identity 
  # for the @Microsoft.KeyVault() references.
  key_vault_reference_identity_id = var.laravel_user_managed_id
}


# Connect the SLOT to the VNet
resource "azurerm_app_service_slot_virtual_network_swift_connection" "staging_vnet" {
  app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
  slot_name      = azurerm_linux_web_app_slot.staging.name
  subnet_id      = var.appservice_subnet_id 
  # Ensure the main app is fully integrated before touching the slot
  depends_on = [azurerm_app_service_virtual_network_swift_connection.vnet_integration]
}



# # Custom Domain and SSL with Azure Front Door 
# # 1. Bind the Custom Domain
# resource "azurerm_app_service_custom_hostname_binding" "custom_domain" {
#   hostname            = var.custom_domain_name
#   app_service_name    = azurerm_linux_web_app.Webapp_Laravel.name
#   resource_group_name = var.resource_group_name
# }

# # 2. Create the Free Managed Certificate
# resource "azurerm_app_service_managed_certificate" "custom_domain_cert" {
#   custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.custom_domain.id
# }

# # 3. Enable HTTPS (SNI)
# resource "azurerm_app_service_certificate_binding" "custom_domain_ssl" {
#   hostname_binding_id = azurerm_app_service_custom_hostname_binding.custom_domain.id
#   certificate_id      = azurerm_app_service_managed_certificate.custom_domain_cert.id
#   ssl_state           = "SniEnabled"
# }




# Configure auto-scalling cpu utilization hits 70%
resource "azurerm_monitor_autoscale_setting" "app_autoscale" {
  name                = "autoscale-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.app_service_plan_laravel.id # Targets the Plan, not the App

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 3 # Limits your cost so it doesn't scale to infinity
    }

    # RULE 1: SCALE OUT (Add instance if CPU > 70%)
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_service_plan_laravel.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M" # Wait 5 mins before scaling again
      }
    }

    # RULE 2: SCALE IN (Remove instance if CPU < 30%)
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_service_plan_laravel.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

