variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "portal_domain_name" {
  description = "Domain name for the deceptive portal"
  type        = string
  default     = "portal.internal"
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "key_vault_id" {
  description = "ID of the Key Vault for storing secrets"
  type        = string
}

variable "honey_user_count" {
  description = "Number of honey user accounts to create"
  type        = number
}

variable "honey_users" {
  description = "List of honey users with their credentials from identity module"
  type = list(object({
    username   = string
    email      = string
    password   = string
    department = string
    job_title  = string
  }))
}
