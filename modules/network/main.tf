resource "azurerm_virtual_network" "VNET_terraform" {
  name                = "terraform-vnet"
  address_space       = [var.addr_space]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "SUBNET_prod_subnet" {
  name                 = "production-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.prod_subnet_prefixes]
}
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.db_subnet_prefixes]

  # Delegate this subnet specifically to MySQL Flexible Server
  # delegation {
  #   name = "mysql_delegation"
  #   service_delegation {
  #     name    = "Microsoft.DBforMySQL/flexibleServers"
  #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  #   }
  # }
}

resource "azurerm_subnet" "appservice_subnet" {
  name                 = "appservice-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.appservice_subnet_prefixes]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]

  # Delegate this subnet to app service to allow VNet Integration
  delegation {
    name = "webapp_delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "pe_subnet" {
  name                 = "private-endpoint-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.pe_subnet_prefixes]
  # DO NOT add a delegation block here
}
resource "azurerm_subnet" "waf_snet" {
  name                 = "snet-waf"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.waf_subnet_prefix]
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-appgw-prod"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard" # Required for v2 Gateway
}

#Flexible server
# # Create a Private DNS Zone (So app can find DB by name)
# resource "azurerm_private_dns_zone" "db_dns" {
#   name                   = "privatelink.mysql.database.azure.com"
#   resource_group_name = var.resource_group_name
# }
# resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
#   name                  = "db-dns-link"
#   private_dns_zone_name = azurerm_private_dns_zone.db_dns.name
#   virtual_network_id    = azurerm_virtual_network.VNET_terraform.id
#   resource_group_name   = var.resource_group_name
#   registration_enabled  = false
# }




# # Wait 30 seconds after the subnet is modified/created
# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [azurerm_subnet.appservice_subnet]
#   create_duration = "30s"
# }

# # Link the Main App ONLY after the timer finishes
# resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
#   app_service_id = var.app_service_id
#   subnet_id      = azurerm_subnet.appservice_subnet.id
  
#   depends_on = [time_sleep.wait_30_seconds]
# }

# # Link the Staging Slot after the Main App is done
# resource "azurerm_app_service_slot_virtual_network_swift_connection" "staging_vnet" {
#   app_service_id = var.app_service_id
#   slot_name      = var.slot_name
#   subnet_id      = azurerm_subnet.appservice_subnet.id
  
#   depends_on = [azurerm_app_service_virtual_network_swift_connection.vnet_integration]
# }



# # Create the Private DNS Zone (Must have this specific name)
# resource "azurerm_private_dns_zone" "app_service_zone" {
#   name                = "privatelink.azurewebsites.net"
#   resource_group_name = var.resource_group_name
# }

# # Link the DNS Zone to your VNet so the App Gateway can use it
# resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
#   name                  = "vnet-dns-link"
#   resource_group_name   = var.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.app_service_zone.name
#   virtual_network_id    = azurerm_virtual_network.vnet.id
# }

# # Create the A Record to map the App Name to the Private IP
# resource "azurerm_private_dns_a_record" "app_service_a_record" {
#   name                = var.webapp_name # Your app name
#   zone_name           = azurerm_private_dns_zone.app_service_zone.name
#   resource_group_name = var.resource_group_name
#   ttl                 = 300
#   records             = var.pdnsz_record_private_ip_address
# }

