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

# Admin Portal Backend Variables
variable "admin_portal_name" {
  description = "Name of the Admin Portal Backend app"
  type        = string
  default     = "admin-portal"
}

variable "admin_portal_sku" {
  description = "SKU for Admin Portal App Service Plan"
  type        = string
  default     = "B1"
}

# Internal API Gateway Variables
variable "api_gateway_name" {
  description = "Name of the Internal API Gateway app"
  type        = string
  default     = "internal-api"
}

variable "api_gateway_sku" {
  description = "SKU for API Gateway App Service Plan"
  type        = string
  default     = "B1"
}

# HR Document Manager Variables
variable "hr_doc_manager_name" {
  description = "Name of the HR Document Manager app"
  type        = string
  default     = "hr-docs"
}

variable "hr_doc_manager_sku" {
  description = "SKU for HR Document Manager App Service Plan"
  type        = string
  default     = "B1"
}
