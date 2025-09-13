# Main configuration for identity deception

# Create honey user accounts with realistic names
resource "azuread_user" "honey_users" {
  count               = var.honey_user_count
  user_principal_name = lower("${local.user_combinations[count.index].first_name}.${local.user_combinations[count.index].last_name}@${data.azuread_domains.current.domains[0].domain_name}")
  display_name        = "${local.user_combinations[count.index].first_name} ${local.user_combinations[count.index].last_name}"
  password            = random_password.user_passwords[count.index].result
  job_title          = local.user_combinations[count.index].job_title
  department         = local.user_combinations[count.index].department
  
  force_password_change = true
  account_enabled      = true
}

# Generate random passwords for honey users that meet Azure AD complexity requirements
resource "random_password" "user_passwords" {
  count            = var.honey_user_count
  length           = 16
  special          = true
  override_special = "!@#$%^&*"
  min_special      = 1
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

# Wait for key vault access policy to be ready
resource "time_sleep" "wait_30_seconds" {
  depends_on = [data.azurerm_key_vault.existing_kv]
  create_duration = "30s"
}

# Store honey user credentials in Key Vault with realistic names
resource "azurerm_key_vault_secret" "honey_user_creds" {
  count        = var.honey_user_count
  name         = replace(lower("user-${local.user_combinations[count.index].first_name}-${local.user_combinations[count.index].last_name}-${substr(sha256(timestamp()), 0, 8)}"), " ", "-")
  value        = jsonencode({
    username   = azuread_user.honey_users[count.index].user_principal_name
    password   = random_password.user_passwords[count.index].result
    email      = azuread_user.honey_users[count.index].user_principal_name
    department = azuread_user.honey_users[count.index].department
    job_title  = azuread_user.honey_users[count.index].job_title
  })
  content_type = "application/json"
  key_vault_id = var.key_vault_id

  depends_on = [
    azuread_user.honey_users,
    time_sleep.wait_30_seconds
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name # Ignore changes to name as it contains a timestamp
    ]
  }
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

# Data source for Key Vault
data "azurerm_key_vault" "existing_kv" {
  name                = split("/", var.key_vault_id)[8]
  resource_group_name = split("/", var.key_vault_id)[4]
}

# Generate unique suffixes for secret names
resource "random_string" "suffix" {
  count   = var.honey_user_count
  length  = 6
  special = false
  upper   = false
}

