# Output values from the root module

output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.deception.name
}

output "honey_user_count" {
  description = "Number of honey user accounts created"
  value       = var.honey_user_count
}

output "identity_honey_users" {
  description = "Honey users from identity_deception module"
  value       = module.identity_deception.honey_users
  sensitive   = true
}

output "monitoring_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  value       = module.monitoring.log_analytics_workspace_id
}

output "monitoring_function_app_name" {
  description = "Name of the monitoring Function App"
  value       = module.monitoring.function_app_name
}

output "sentinel_workspace_id" {
  description = "Microsoft Sentinel workspace ID"
  value       = module.monitoring.sentinel_workspace_id
}