# Outputs for the monitoring module

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.autopot_monitoring.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.autopot_monitoring.name
}

output "application_insights_id" {
  description = "The ID of the Application Insights instance"
  value       = azurerm_application_insights.autopot_monitoring.id
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.autopot_monitoring.instrumentation_key
  sensitive   = true
}

output "function_app_id" {
  description = "The ID of the monitoring Function App"
  value       = azurerm_linux_function_app.monitoring_functions.id
}

output "function_app_name" {
  description = "The name of the monitoring Function App"
  value       = azurerm_linux_function_app.monitoring_functions.name
}

output "sentinel_workspace_id" {
  description = "The ID of the Sentinel workspace"
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.autopot_sentinel.workspace_id
}
