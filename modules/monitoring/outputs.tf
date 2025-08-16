output "workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.deception.id
}

output "workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.deception.name
}

output "workspace_key" {
  description = "The primary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.deception.primary_shared_key
  sensitive   = true
}

output "action_group_id" {
  description = "The ID of the Slack action group"
  value       = azurerm_monitor_action_group.slack.id
}

output "alert_rule_ids" {
  description = "Map of alert rule IDs"
  value = {
    honey_user_signin = azurerm_monitor_scheduled_query_rules_alert.honey_user_signin.id
    decoy_app_access  = azurerm_monitor_scheduled_query_rules_alert.decoy_app_access.id
    suspicious_ip     = azurerm_monitor_scheduled_query_rules_alert.suspicious_ip.id
  }
}
