# Example root configuration showing how to use both modules

# Use applications module
module "applications" {
  source = "./modules/applications"

  resource_group_name = var.resource_group_name
  location           = var.location
  environment        = var.environment
  project_name       = var.project_name

  # Optional: customize app names and SKUs
  admin_portal_name   = "admin-portal"
  api_gateway_name    = "internal-api"
  hr_doc_manager_name = "hr-docs"

  tags = {
    Owner = "Security Team"
  }
}

# Use monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name        = var.resource_group_name
  location                   = var.location
  environment               = var.environment
  project_name              = var.project_name
  
  # Key Vault reference for Slack webhook
  slack_webhook_key_vault_id = azurerm_key_vault.deception.id
  
  # Customize monitoring settings
  retention_in_days = 90
  alert_severity    = 1
  alert_frequency   = 5
  alert_time_window = 5

  tags = {
    Owner = "Security Team"
  }

  # Important: Add explicit dependency to ensure monitoring is created after apps
  depends_on = [module.applications]
}
