# Implementing  observability stack
# 1. Create the Storage (Log Analytics)
resource "azurerm_log_analytics_workspace" "log_analytics_wksp" {
  name                = "laravel-log-workspace"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 2. Create the APM (Application Insights)
resource "azurerm_application_insights" "appinsights" {
  name                = "laravel-app-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_wksp.id
  application_type    = "web"
  # Force Terraform to wait until the Workspace is fully confirmed
  depends_on = [azurerm_log_analytics_workspace.log_analytics_wksp]
}

# 3. Connect to Web App via App Settings using ENV variables (see above in azurerm_linux_web_app resource)

# Send Nginx logs and Startup Script logs to Log Analytics for troubleshooting
resource "azurerm_monitor_diagnostic_setting" "webapp_logs" {
  name                       = "web-app-logs-to-log-analytics"
  target_resource_id         = var.web_app_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_wksp.id

  enabled_log {
    category = "AppServiceConsoleLogs" # Captures your .sh script output
  }
  enabled_log {
    category = "AppServiceHTTPLogs"    # Captures Nginx traffic
  }
}

# Notification Channel
resource "azurerm_monitor_action_group" "sre_alerts" {
  name                = "sre-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "SREAlerts"

  email_receiver {
    name                    = "Kelvin-DevOps"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# App Service Health Alert (5xx Errors)
resource "azurerm_monitor_metric_alert" "app_5xx_alert" {
  name                = "alert-app-5xx"
  resource_group_name = var.resource_group_name
  scopes              = [var.web_app_id]
  severity            = 1 # Critical

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_alerts.id
  }
}

#  Database Performance Alert (CPU)
resource "azurerm_monitor_metric_alert" "db_cpu_alert" {
  name                = "alert-sql-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = [var.production_db_id]
  description         = "Action will be triggered when CPU exceeds 85% for 5 minutes."
  severity            = 1 # 0: Critical, 1: Error, 2: Warning
  frequency           = "PT1M" # Check every minute
  window_size         = "PT5M" # Look at data over the last 5 minutes

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_alerts.id
  }
}