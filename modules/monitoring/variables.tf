variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging and naming"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
  default     = "autopot-logs"
}

variable "retention_in_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "slack_webhook_key_vault_id" {
  description = "ID of the Key Vault containing the Slack webhook URL"
  type        = string
}

variable "slack_webhook_secret_name" {
  description = "Name of the Key Vault secret containing the Slack webhook URL"
  type        = string
  default     = "slack-webhook-url"
}


variable "alert_severity" {
  description = "Severity level for alerts (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)"
  type        = number
  default     = 1
}

variable "alert_frequency" {
  description = "How often to run the alert query in minutes"
  type        = number
  default     = 5
}

variable "alert_time_window" {
  description = "Time window for the alert query in minutes"
  type        = number
  default     = 5
}
