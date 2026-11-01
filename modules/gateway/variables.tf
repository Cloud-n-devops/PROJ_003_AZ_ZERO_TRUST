# Root variables
variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}

variable "waf_policy_id" {
  type = string
}
variable "public_ip_id" {
  type = string
}
variable "waf_subnet_id" {
  type = string
}
variable "webapp_url" {
  type = string
}
variable "webapp_url_staging" {
  type = string
}
variable "gtw_managed_user_id" {
  type = string
}
variable "kv_ssl_cert_name" {
  type = string
}
variable "key_vault_id" {
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
# variable "ssl_pfx_password" {
#   type = string
# }
