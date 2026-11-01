output "appservice_subnet_id" {
  value = azurerm_subnet.appservice_subnet.id
}
output "db_subnet_id" {
  value = azurerm_subnet.db_subnet.id
}
output "waf_subnet_id" {
  value = azurerm_subnet.waf_snet.id
}
output "pe_subnet_id" {
  value = azurerm_subnet.pe_subnet.id
}

# output "private_dns_zone_id" {
#   value = azurerm_private_dns_zone.db_dns.id
# }
# output "private_dns_vnet_link_id" {
#   value = azurerm_private_dns_zone_virtual_network_link.dns_link.id
# }
output "vnet_id" {
  value = azurerm_virtual_network.VNET_terraform.id
}
output "public_ip_id" {
  value = azurerm_public_ip.appgw_pip.id
}
output "public_ip_address" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

