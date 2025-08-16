# Main configuration for AutoPot deployment

# Data source for current Azure subscription
data "azurerm_subscription" "current" {}

# Data source for current Azure AD tenant
data "azuread_client_config" "current" {}

# Resource group for AutoPot resources
  # Already created in the shell script (variables)




#Assigning keyVault admin role 
resource "azurerm_role_assignment" "kv_admin" {
  principal_id   = data.azuread_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope          = azurerm_key_vault.deception.id
}


# Key Vault for storing sensitive information
resource "azurerm_key_vault" "deception" {
  name                = "kvault01-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azuread_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

}

# Add access policy for Terraform service principal
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.deception.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = "47d7254e-37cf-42b4-9bb4-df5267339571"  # Terraform Service Principal Object ID

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

# Deploy deceptive identities
module "identity_deception" {
  source           = "./modules/identity"
  key_vault_id     = azurerm_key_vault.deception.id
  honey_user_count = var.honey_user_count
}

# Deploy deceptive applications
module "applications" {
  source = "./modules/applications"

  resource_group_name = var.resource_group_name
  location           = var.location
  environment        = var.environment
  project_name       = var.project_name

  # Optional: Override default SKUs (F1->Free plan  -  P1v2->premium plan)
  admin_portal_sku    = "F1"
  api_gateway_sku     = "F1"
  hr_doc_manager_sku  = "F1"

}

# Deploy monitoring and alerting
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name        = "your-resource-group"
  location                   = "francecentral"
  environment               = "dev"
  project_name              = "autopot"
  
  # Key Vault reference for Slack webhook
  slack_webhook_key_vault_id = azurerm_key_vault.main.id
  
  # Optional: customize alert settings
  alert_severity    = 1  # Error
  alert_frequency   = 5  # minutes
  alert_time_window = 5  # minutes
  
  # Optional: adjust log retention
  retention_in_days = 90
  
  # Additional tags
  tags = {
    Owner = "Security Team"
  }
}
