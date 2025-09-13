# Main configuration for AutoPot deployment

# Data source for current Azure subscription
data "azurerm_subscription" "current" {}

# Data source for current Azure AD tenant
data "azuread_client_config" "current" {}

# Resource group for AutoPot resources
  # Already created in the shell script (variables)


# Assigning Key Vault admin role 
resource "azurerm_role_assignment" "kv_admin" {
  depends_on = [azurerm_key_vault.deception]
  principal_id         = data.azuread_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope               = azurerm_key_vault.deception.id

  timeouts {
    create = "5m"
  }
}


# Key Vault for storing sensitive information
resource "azurerm_key_vault" "deception" {
  name                        = "kvtest62-${var.project_name}-${var.environment}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azuread_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  enable_rbac_authorization   = false
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

# Add access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "terraform" {
  depends_on = [azurerm_key_vault.deception]
  key_vault_id = azurerm_key_vault.deception.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = data.azuread_client_config.current.object_id

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set"
  ]
}



# Deploy deceptive identities
module "identity_deception" {
  source           = "./modules/identity"
  key_vault_id     = azurerm_key_vault.deception.id
  honey_user_count = var.honey_user_count
}

# Wait for identity module to complete
resource "time_sleep" "wait_for_identity" {
  depends_on = [module.identity_deception]
  create_duration = "30s"
}

# Deploy deceptive applications
module "application_deception" {
  depends_on = [
    azurerm_key_vault_access_policy.terraform,
    time_sleep.wait_for_identity
  ]

  source              = "./modules/applications"
  location            = var.location
  resource_group_name = var.resource_group_name
  key_vault_id        = azurerm_key_vault.deception.id
  honey_user_count    = var.honey_user_count
  honey_users         = module.identity_deception.honey_users
  sql_admin_username  = "sqladmin"
  sql_admin_password  = "P@ssw0rd123!"  # This is intentionally weak for deception
}

# Deploy monitoring and alerting
module "monitoring" {
  depends_on = [
    module.identity_deception,
    module.application_deception
  ]

  source              = "./modules/monitoring"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Key Vault monitoring
  key_vault_id  = azurerm_key_vault.deception.id
  key_vault_uri = azurerm_key_vault.deception.vault_uri
  
  # SQL Server monitoring
  sql_server_id   = module.application_deception.sql_server_id
  sql_server_name = module.application_deception.sql_server_name
  sql_database_id = module.application_deception.sql_database_id
  
  # App Service monitoring
  app_service_id = module.application_deception.app_service_id
  
  # Honey users for monitoring
  honey_users = module.identity_deception.honey_users
  
  # Slack webhook URL (should be provided as variable)
  slack_webhook_url = var.slack_webhook_url
}

