variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "autopot"
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "The Azure rg where all resources will be stored"
  type    = string
  default = "rg-autopot"
}


variable "honey_user_count" {
  description = "Number of honey user accounts to create"
  type        = number
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for security notifications"
  type        = string
  sensitive   = true
}


