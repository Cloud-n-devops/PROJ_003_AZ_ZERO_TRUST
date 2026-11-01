# Global Variables
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "project_name" {
  type = string
}
variable "admin_user_email" {
  type = string
}

# App Service Variables
variable "laravel_credentials" {
  type = any
  description = "Laravel db user and pass"
}

# Network variables
variable "vnet_id" {
  type = string
}
variable "db_subnet_id" {
  type = string
}
variable "pe_subnet_id" {
  type = string
}

# variable "private_dns_zone_id" {
#   type = string
# }
# variable "private_dns_vnet_link_id" {
#   type    = string
# }

# db variables
# variable "random_password_db_admin_pass" {
#   type = string
#   description = "Database random generated password"
# }
variable "laravel_user_managed_object_id" {
  type = string
}