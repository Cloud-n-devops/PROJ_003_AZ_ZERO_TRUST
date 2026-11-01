# Resource Locks

# # Lock the Resource Group to prevent accidental deletion of the whole project
# resource "azurerm_management_lock" "rg_lock" {
#   name       = "project-level-lock"
#   scope      = var.resource_group_id
#   lock_level = "CanNotDelete"
#   notes      = "This Resource Group contains Elara production resources. Deletion is prohibited via Terraform."
# }

# # Optional: Specifically lock the Database to be extra safe
# resource "azurerm_management_lock" "db_lock" {
#   name       = "database-protection-lock"
#   scope      = var.db_server_id 
#   lock_level = "CanNotDelete"
#   notes      = "Critical Database: Cannot be deleted without manually removing this lock."
# }
# resource "azurerm_management_lock" "vnet_lock" {
#   name       = "vnet-critical-lock"
#   scope      = var.vnet_id
#   lock_level = "CanNotDelete"
#   notes      = "Preventing VNet deletion to protect delegated subnets."
# }




# Budget constrains 
resource "azurerm_consumption_budget_resource_group" "elara_budget" {
  name              = "budget-${var.project_name}"
  resource_group_id = var.resource_group_id
  amount            = 10 # Your monthly limit in USD
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-04-01T00:00:00Z" # Must be 1st of the month
  }

  notification {
    enabled   = true
    threshold = 50.0 # Alert at $5
    operator  = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled   = true
    threshold = 100.0 # Alert at $10
    operator  = "GreaterThan"
    contact_emails = [var.alert_email]
  }
}


# Dynamically find the built-in policy by its common name
data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

#Policy based
# Define the Policy: Only Allow Specific Locations
resource "azurerm_subscription_policy_assignment" "location_policy" {
  name                 = "location-lockdown"
  subscription_id      = var.subscription_id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  display_name         = "Limit Resource Deployment Regions"

  parameters = <<PARAMS
    {
      "listOfAllowedLocations": {
        "value": ["East US", "West US", "westeurope"]
      }
    }
PARAMS
}

# # Key Vault for Secrets (The Professional Way)
# resource "azurerm_key_vault" "main_vault" {
#   name                        = "kv-laravel-prod-001"
#   location                    = var.location
#   resource_group_name         = var.resource_group_name
#   enabled_for_disk_encryption = true
#   tenant_id                   = var.tenant_id
#   sku_name                    = "standard"

#   # Secure by default: No public access
#   network_acls {
#     bypass         = "AzureServices"
#     default_action = "Deny"
#   }
# }