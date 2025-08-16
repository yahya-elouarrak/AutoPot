# Monitoring Module for AutoPot


# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "deception" {
  name                = "${var.workspace_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Free" #(PerGB2018 for a paid plan)
  retention_in_days   = var.retention_in_days
}


# Action Group for Slack notifications
resource "azurerm_monitor_action_group" "slack" {
  name                = "slack-notify-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name         = "slack"

  webhook_receiver {
    name                   = "slack"
    service_uri           = "@Microsoft.KeyVault(SecretUri=${var.slack_webhook_key_vault_id}/secrets/${var.slack_webhook_secret_name})"
    use_common_alert_schema = true
  }
}

# Scheduled query rules for honey user sign-ins
resource "azurerm_monitor_scheduled_query_rules_alert" "honey_user_signin" {
  name                = "honey-user-signin-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.slack.id]
  }

  data_source_id = azurerm_log_analytics_workspace.deception.id
  description    = "Alert when honey user accounts are accessed"
  enabled        = true
  
  query         = <<-QUERY
    SigninLogs
    | where UserPrincipalName contains "honey"
    | where ResultType != 0  // Failed sign-in attempts
    | project TimeGenerated, UserPrincipalName, IPAddress, Location, ResultType, ResultDescription
  QUERY
  
  severity    = var.alert_severity
  frequency   = var.alert_frequency
  time_window = var.alert_time_window

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

}

# Query rule for decoy app access
resource "azurerm_monitor_scheduled_query_rules_alert" "decoy_app_access" {
  name                = "decoy-app-access-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.slack.id]
  }

  data_source_id = azurerm_log_analytics_workspace.deception.id
  description    = "Alert when decoy applications are accessed"
  enabled        = true
  
  query         = <<-QUERY
    AuditLogs
    | where TargetResources has "purpose: decoy"
    | where OperationName has "Application"
    | project TimeGenerated, OperationName, Result, Identity, TargetResources, InitiatedBy
  QUERY
  
  severity    = var.alert_severity
  frequency   = var.alert_frequency
  time_window = var.alert_time_window

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

}

# Query rule for suspicious IP addresses
resource "azurerm_monitor_scheduled_query_rules_alert" "suspicious_ip" {
  name                = "suspicious-ip-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.slack.id]
  }

  data_source_id = azurerm_log_analytics_workspace.deception.id
  description    = "Alert on access from suspicious IP addresses"
  enabled        = true
  
  query         = <<-QUERY
    union SigninLogs, AuditLogs
    | where TargetResources has "purpose: decoy" or UserPrincipalName contains "honey"
    | where isnotempty(IPAddress)
    | where ipv4_is_private(IPAddress) == false  // Exclude private IP ranges
    | summarize count() by IPAddress, bin(TimeGenerated, 5m)
    | where count_ > 5  // Threshold for suspicious activity
  QUERY
  
  severity    = var.alert_severity
  frequency   = var.alert_frequency
  time_window = var.alert_time_window

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

}

# Diagnostic settings for Azure AD logs
resource "azurerm_monitor_diagnostic_setting" "aad" {
  name                       = "aad-to-log-analytics"
  target_resource_id        = "/providers/microsoft.aadiam/diagnosticSettings/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.deception.id

  log {
    category = "SignInLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.retention_in_days
    }
  }

  log {
    category = "AuditLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.retention_in_days
    }
  }
}
