# Global Variables
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}


# Network variables
variable "addr_space" {
    type = string
    description = "address space for terraform vnet"
}
variable "prod_subnet_prefixes" {
  type = string
  description = "Production subnet prefixes"
}
variable "db_subnet_prefixes" {
  type = string
  description = "Production subnet prefixes"
}
variable "appservice_subnet_prefixes" {
  type = string
  description = "Production subnet prefixes"
}
variable "pe_subnet_prefixes" {
  type = string
  description = "private endpoint subnet prefixes"
}
variable "waf_subnet_prefix" {
  type = string
  description = "WAF endpoint subnet prefixes"
}






# App Service variables
# variable "app_service_id" { 
#   type = string
# }
# variable "slot_name" { 
#   type = string
# }