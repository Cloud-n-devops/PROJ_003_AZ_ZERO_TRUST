# This looks up the secret based on a variable
data "azurerm_key_vault_secret" "ssl_cert" {
  name         = var.kv_ssl_cert_name
  key_vault_id = var.key_vault_id
}

locals {
  backend_port = 443
  backend_protocol = "Https"
  
  prod_port = 80
  staging_port = 8080
  protocol = "Http"

  prod_https_listener_name = "prod-https-listener"
  prod_http_listener_name = "prod-http-listener"
  staging_https_listener_name = "staging-https-listener"
  staging_http_listener_name = "staging-http-listener"

  host_names_port = 443
  host_names_protocol = "Https"
  redirect_configuration_name_prod = "http-to-https"
  redirect_configuration_name_staging = "staging-http-to-https"
}
# Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-laravel-prod"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1 # You can set autoscale_configuration instead
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [var.gtw_managed_user_id]
  }
  ssl_certificate {
    name                = var.ssl_certificate_name
    key_vault_secret_id = data.azurerm_key_vault_secret.ssl_cert.versionless_id
  }
  tags = {
    refresh = "1" # Change this value to "2", "3", etc. to force a refresh
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.waf_subnet_id
  }

  frontend_port {
    name = "port_${local.host_names_port}"
    port = local.host_names_port
  }

  frontend_port {
    name = "port_${local.prod_port}"
    port = local.prod_port
  }
  # # Stagging slot FrontendPort
  # frontend_port {
  #   name = "port_${local.staging_port}"
  #   port = local.staging_port
  # }

  frontend_ip_configuration {
    name                 = "frontend_ip_config"
    public_ip_address_id = var.public_ip_id
  }

  # Points to the specific FQDN of production app
  backend_address_pool {
    name  = "prod-pool"
    fqdns = [replace(replace(var.webapp_url, "/^https?:///", ""), "///", "")]
  }

  # Points to the specific FQDN of staging slot
    backend_address_pool {
    name  = "staging-pool"
    fqdns = [replace(replace(var.webapp_url_staging, "/^https?:///", ""), "///", "")]
    }

  backend_http_settings {
    name                  = "${local.backend_protocol}-backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = local.backend_port
    protocol              = local.backend_protocol
    request_timeout       = 60
    pick_host_name_from_backend_address = true
  }

  # #  production http listener
  # http_listener {
  #   name                           = local.prod_http_listener_name
  #   frontend_ip_configuration_name = "frontend_ip_config"
  #   frontend_port_name             = "port_${local.prod_port}"
  #   protocol                       = local.protocol
  # }
#   # Stagging http listener
#   http_listener {
#   name                           = local.staging_http_listener_name
#   frontend_ip_configuration_name = "frontend_ip_config"
#   frontend_port_name             = "port_${local.staging_port}"
#   protocol                       = local.protocol
# }


http_listener {
    name                           = local.prod_https_listener_name
    frontend_ip_configuration_name = "frontend_ip_config"
    frontend_port_name             = "port_${local.host_names_port}"
    protocol                       = local.host_names_protocol
    ssl_certificate_name           = var.ssl_certificate_name
    host_name                      = var.prod_hostname # 
}

http_listener {
    name                           = local.staging_https_listener_name
    frontend_ip_configuration_name = "frontend_ip_config"
    frontend_port_name             = "port_${local.host_names_port}"
    protocol                       = local.host_names_protocol
    ssl_certificate_name           = var.ssl_certificate_name
    host_name                      = var.staging_hostname # 
}
# Redirect HTTP to HTTPS (production)
  http_listener {
    name                           = local.prod_http_listener_name
    frontend_ip_configuration_name = "frontend_ip_config"
    frontend_port_name             = "port_${local.prod_port}"
    protocol                       = local.protocol
    host_name                      = var.prod_hostname # 
  }
  # Redirect HTTP to HTTPS (staging)
  http_listener {
    name                           = local.staging_http_listener_name
    frontend_ip_configuration_name = "frontend_ip_config"
    frontend_port_name             = "port_${local.prod_port}"
    protocol                       = local.protocol
    host_name                      = var.staging_hostname # 
  }

#   # Production routing rule
#   request_routing_rule {
#     name                       = "rule-1"
#     rule_type                  = "Basic"
#     http_listener_name         = local.prod_http_listener_name
#     backend_address_pool_name  = "prod-pool"
#     backend_http_settings_name = "${local.backend_protocol}-backend-settings"
#     priority                   = 1
#   }
#   # Stagging routing rule
#   request_routing_rule {
#   name                       = "staging-rule"
#   rule_type                  = "Basic"
#   http_listener_name         = local.staging_http_listener_name
#   backend_address_pool_name  = "staging-pool"
#   backend_http_settings_name = "${local.backend_protocol}-backend-settings" # Can reuse the same settings
#   priority                   = 20
# }

redirect_configuration {
    name                 = local.redirect_configuration_name_prod
    redirect_type        = "Permanent"
    target_listener_name = local.prod_https_listener_name
    include_path         = true
    include_query_string = true
}

redirect_configuration {
  name                 = local.redirect_configuration_name_staging
  redirect_type        = "Permanent"
  target_listener_name = local.staging_https_listener_name
  include_path         = true
  include_query_string = true
}

request_routing_rule {
    name                       = "prod-rule"
    rule_type                  = "Basic"
    priority                   = 10
    http_listener_name         = local.prod_https_listener_name
    backend_address_pool_name  = "prod-pool"
    backend_http_settings_name = "${local.backend_protocol}-backend-settings"
}
request_routing_rule {
    name                       = "staging-rule"
    rule_type                  = "Basic"
    priority                   = 20
    http_listener_name         = local.staging_https_listener_name
    backend_address_pool_name  = "staging-pool"
    backend_http_settings_name = "${local.backend_protocol}-backend-settings"
}
request_routing_rule {
  name                        = "http-redirect-rule"
  priority                    = 30
  rule_type                   = "Basic"
  http_listener_name          = local.prod_http_listener_name
  redirect_configuration_name = local.redirect_configuration_name_prod
}
request_routing_rule {
  name                        = "staging-http-redirect-rule"
  priority                    = 40
  rule_type                   = "Basic"
  http_listener_name          = local.staging_http_listener_name
  redirect_configuration_name = local.redirect_configuration_name_staging
}

  firewall_policy_id = var.waf_policy_id
}



# resource "azurerm_application_gateway" "appgw" {
#   name                = "appgw-laravel-prod"
#   resource_group_name = var.rg_name
#   location            = var.location

#   # Link the Identity
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.appgw_id.id]
#   }

#   sku {
#     name     = "WAF_v2"
#     tier     = "WAF_v2"
#     capacity = 1
#   }

#   gateway_ip_configuration {
#     name      = "gateway-ip-config"
#     subnet_id = var.waf_subnet_id
#   }

#   # --- PORTS ---
#   frontend_port { name = "port_80"  port = 80 }
#   frontend_port { name = "port_443" port = 443 }

#   frontend_ip_configuration {
#     name                 = "frontend_ip_config"
#     public_ip_address_id = var.public_ip_id
#   }

#   # --- SSL CERTIFICATE ---
#   ssl_certificate {
#     name                = "gradestar-ssl"
#     key_vault_secret_id = data.azurerm_key_vault_secret.ssl_cert.id
#   }

#   # --- LISTENERS (HTTPS) ---
#   http_listener {
#     name                           = "prod-https-listener"
#     frontend_ip_configuration_name = "frontend_ip_config"
#     frontend_port_name             = "port_443"
#     protocol                       = "Https"
#     ssl_certificate_name           = "gradestar-ssl"
#     host_name                      = "app.gradestarsolutions.com"
#   }

#   # --- REDIRECT (80 to 443) ---
#   redirect_configuration {
#     name                 = "http-to-https"
#     redirect_type        = "Permanent"
#     target_listener_name = "prod-https-listener"
#     include_path         = true
#     include_query_string = true
#   }

#   # --- ROUTING RULES ---
#   request_routing_rule {
#     name                       = "prod-https-rule"
#     priority                   = 10
#     rule_type                  = "Basic"
#     http_listener_name         = "prod-https-listener"
#     backend_address_pool_name  = "prod-pool"
#     backend_http_settings_name = "https-backend-settings"
#   }

#   request_routing_rule {
#     name                        = "http-redirect-rule"
#     priority                    = 20
#     rule_type                   = "Basic"
#     http_listener_name          = "prod-http-listener" # (Define this listener on port 80)
#     redirect_configuration_name = "http-to-https"
#   }
# }
