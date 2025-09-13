# Monitoring Module - Main Configuration
# This module provides comprehensive monitoring for AutoPot honeypot resources
# with Microsoft Sentinel integration and Slack notifications

# Random string for unique resource names
resource "random_string" "monitoring_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "autopot_monitoring" {
  name                = "law-autopot-${random_string.monitoring_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = {
    Environment = "monitoring"
    Purpose     = "honeypot-security"
  }
}

# Microsoft Sentinel (Security Information and Event Management)
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "autopot_sentinel" {
  workspace_id                 = azurerm_log_analytics_workspace.autopot_monitoring.id
  customer_managed_key_enabled = false
}

# Application Insights for web app monitoring
resource "azurerm_application_insights" "autopot_monitoring" {
  name                = "ai-autopot-${random_string.monitoring_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.autopot_monitoring.id
  application_type    = "web"

  tags = {
    Environment = "monitoring"
    Purpose     = "honeypot-security"
  }
}

# Storage Account for Function App
resource "azurerm_storage_account" "monitoring_functions" {
  name                     = "stmonitoring${random_string.monitoring_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier            = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = "monitoring"
    Purpose     = "honeypot-security"
  }
}

# Service Plan for Function App
resource "azurerm_service_plan" "monitoring_functions" {
  name                = "asp-monitoring-${random_string.monitoring_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type            = "Linux"
  sku_name           = "Y1"  # Consumption plan
}

# Function App for Slack notifications and custom monitoring logic
resource "azurerm_linux_function_app" "monitoring_functions" {
  name                = "func-autopot-monitoring-${random_string.monitoring_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.monitoring_functions.id
  storage_account_name       = azurerm_storage_account.monitoring_functions.name
  storage_account_access_key = azurerm_storage_account.monitoring_functions.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
    
    application_insights_key               = azurerm_application_insights.autopot_monitoring.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.autopot_monitoring.connection_string
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "SLACK_WEBHOOK_URL"           = var.slack_webhook_url
    "LOG_ANALYTICS_WORKSPACE_ID"  = azurerm_log_analytics_workspace.autopot_monitoring.workspace_id
    "LOG_ANALYTICS_WORKSPACE_KEY" = azurerm_log_analytics_workspace.autopot_monitoring.primary_shared_key
    "KEYVAULT_URI"               = var.key_vault_uri
    "SQL_SERVER_NAME"            = var.sql_server_name
    "RESOURCE_GROUP_NAME"        = var.resource_group_name
    "SUBSCRIPTION_ID"            = data.azurerm_client_config.current.subscription_id
  }

  tags = {
    Environment = "monitoring"
    Purpose     = "honeypot-security"
  }
}

# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# Role assignment for Function App to read logs
resource "azurerm_role_assignment" "function_log_reader" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_linux_function_app.monitoring_functions.identity[0].principal_id
}

# Role assignment for Function App to read Key Vault
resource "azurerm_role_assignment" "function_keyvault_reader" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.monitoring_functions.identity[0].principal_id
}

# Role assignment for Function App to read SQL Server logs
resource "azurerm_role_assignment" "function_sql_reader" {
  scope                = var.sql_server_id
  role_definition_name = "SQL Security Manager"
  principal_id         = azurerm_linux_function_app.monitoring_functions.identity[0].principal_id
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault_diagnostics" {
  name                       = "keyvault-diagnostics"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for SQL Server
resource "azurerm_monitor_diagnostic_setting" "sql_server_diagnostics" {
  name                       = "sql-server-diagnostics"
  target_resource_id         = var.sql_server_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  enabled_log {
    category = "DevOpsOperationsAudit"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for SQL Database
resource "azurerm_monitor_diagnostic_setting" "sql_database_diagnostics" {
  name                       = "sql-database-diagnostics"
  target_resource_id         = var.sql_database_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "QueryStoreWaitStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  enabled_log {
    category = "DatabaseWaitStatistics"
  }

  enabled_log {
    category = "Timeouts"
  }

  enabled_log {
    category = "Blocks"
  }

  enabled_log {
    category = "Deadlocks"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic settings for App Service
resource "azurerm_monitor_diagnostic_setting" "app_service_diagnostics" {
  name                       = "app-service-diagnostics"
  target_resource_id         = var.app_service_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
