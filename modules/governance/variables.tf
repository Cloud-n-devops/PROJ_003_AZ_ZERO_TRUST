# Global Variables
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "resource_group_id" {
  type = string
}
variable "db_server_id" {
  type = string
}
variable "vnet_id" {
  type = string
}
# variable "appservice_subnet_id" {
#   type = string
# }
variable "project_name" {
  type = string   
}
# variable "environment" {
#   type = string
# } 
variable "alert_email" {
  type = string
  
}
variable "subscription_id" {
  type = string
}
variable "tenant_id" {
  type = string
}
