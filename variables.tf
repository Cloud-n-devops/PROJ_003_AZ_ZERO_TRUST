variable "project_name" {
  type = string
  description = "The name of the project"
}
variable "environment" {
  type = string
}
variable "admin_user_email" {
  type = string
}

variable "prod_location" {
    type = string
    description = "production Location"
    default = "eastus"
}
variable "addr_space" {
    type = string
}
variable "prod_subnet_prefixes" {
  type = string

}
variable "db_subnet_prefixes" {
  type = string
}
variable "appservice_subnet_prefixes" {
  type = string
}
variable "pe_subnet_prefixes" {
  type = string
}
variable "waf_subnet_prefix" {
  type = string
}


# variable "laravel_app_repo" {
#   type= string
#   description = "Laravel app github repo"
#   default = "https://github.com/kevohmwach/ElaraH.git"
# }
variable "laravel_credentials" {
  type = any
  description = "Laravel db user and pass"
}
variable "email_address" {
  type = any
  description = "List of email addresses to receive alerts"
}
variable "custom_domain_name" {
  type = string
  description = "Custom domain name to bind to the App Service"
}
variable "custom_domain_enabled" {
  type = bool
  default = false
  description = "Whether to enable custom domain configuration for the App Service"
}
variable "webapp_default_url" {
  type = string
  description = "The default URL of the web app (used if custom domain is not enabled)"
}
variable "kv_ssl_cert_name" {
  type = string
}
variable "prod_hostname" {
  type = string
}
variable "staging_hostname" {
  type = string
}
variable "ssl_certificate_name" {
  type = string
}
