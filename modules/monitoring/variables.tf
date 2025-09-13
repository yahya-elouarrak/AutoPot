# Variables for the monitoring module

variable "location" {
  description = "The Azure region where monitoring resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "key_vault_id" {
  description = "The ID of the Key Vault to monitor"
  type        = string
}

variable "key_vault_uri" {
  description = "The URI of the Key Vault"
  type        = string
}

variable "sql_server_id" {
  description = "The ID of the SQL Server to monitor"
  type        = string
}

variable "sql_server_name" {
  description = "The name of the SQL Server"
  type        = string
}

variable "sql_database_id" {
  description = "The ID of the SQL Database to monitor"
  type        = string
}

variable "app_service_id" {
  description = "The ID of the App Service to monitor"
  type        = string
}

variable "honey_users" {
  description = "List of honey users to monitor"
  type = list(object({
    username   = string
    email      = string
    password   = string
    department = string
    job_title  = string
    object_id  = string
  }))
  sensitive = true
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
}
