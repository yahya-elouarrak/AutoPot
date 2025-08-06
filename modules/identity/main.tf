# Main configuration for identity deception

# Create honey user accounts
resource "azuread_user" "honey_users" {
  count               = var.honey_user_count
  user_principal_name = "honeyuser${count.index + 1}@${data.azuread_domains.current.domains[0].domain_name}"
  display_name        = "Honey User ${count.index + 1}"
  password            = random_password.user_passwords[count.index].result
  
  force_password_change = true
  account_enabled      = true
}

# Generate random passwords for honey users
resource "random_password" "user_passwords" {
  count            = var.honey_user_count
  length           = 16
  special          = true
  override_special = "!@#$%"
}

# Store honey user credentials in Key Vault
resource "azurerm_key_vault_secret" "honey_user_creds" {
  count        = var.honey_user_count
  name         = "honey-user-${count.index + 1}-password"
  value        = random_password.user_passwords[count.index].result
  key_vault_id = var.key_vault_id

}

# Create honey group
resource "azuread_group" "honey_group" {
  display_name     = "Privileged Access Review Group"
  security_enabled = true
  description      = "High-privilege group for deception purposes"
}

# Add honey users to honey group
resource "azuread_group_member" "honey_group_members" {
  count            = var.honey_user_count
  group_object_id  = azuread_group.honey_group.id
  member_object_id = azuread_user.honey_users[count.index].id
}

# Data source for Azure AD domain
data "azuread_domains" "current" {
  only_initial = true
}
