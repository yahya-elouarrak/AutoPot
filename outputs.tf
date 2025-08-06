# Output values from the root module

output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.deception.name
}

output "workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = module.monitoring.workspace_name
}

output "honey_user_count" {
  description = "Number of honey user accounts created"
  value       = var.honey_user_count
}