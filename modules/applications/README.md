# Applications Module

This module creates three decoy applications in Azure Active Directory and deploys them as web apps:

1. Admin Portal Backend + credentials file. /file.txt 

autopot.com
/login.php 
/.sensitive.txt


## Features

- Creates Azure AD applications with proper OAuth2 and OpenID Connect configurations
- Deploys Linux-based web apps in Azure App Service
- Configures Azure AD authentication for each app
- Applies consistent tagging for decoy identification
- Supports custom SKUs and names through variables

## Usage

```hcl
module "applications" {
  source = "./modules/applications"

  resource_group_name = "your-resource-group"
  location           = "francecentral"
  environment        = "dev"
  project_name       = "autopot"

  # Optional: Override default app names
  admin_portal_name    = "custom-admin-portal"
  api_gateway_name     = "custom-api-gateway"
  hr_doc_manager_name  = "custom-hr-docs"

  # Optional: Override default SKUs
  admin_portal_sku    = "P1v2"
  api_gateway_sku     = "P1v2"
  hr_doc_manager_sku  = "P1v2"

  # Additional tags
  tags = {
    Owner = "Security Team"
  }
}
```

## Requirements

- Azure subscription
- Azure AD tenant
- Terraform >= 1.0
- AzureRM provider >= 3.0
- AzureAD provider >= 2.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | string | n/a | yes |
| location | Azure region for resources | string | n/a | yes |
| environment | Environment name for tagging | string | n/a | yes |
| project_name | Project name for tagging | string | n/a | yes |
| admin_portal_name | Name of Admin Portal app | string | "admin-portal" | no |
| api_gateway_name | Name of API Gateway app | string | "internal-api" | no |
| hr_doc_manager_name | Name of HR Doc Manager app | string | "hr-docs" | no |
| admin_portal_sku | SKU for Admin Portal | string | "B1" | no |
| api_gateway_sku | SKU for API Gateway | string | "B1" | no |
| hr_doc_manager_sku | SKU for HR Doc Manager | string | "B1" | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| admin_portal_app_id | Application ID of Admin Portal |
| admin_portal_object_id | Object ID of Admin Portal |
| admin_portal_url | URL of Admin Portal web app |
| api_gateway_app_id | Application ID of API Gateway |
| api_gateway_object_id | Object ID of API Gateway |
| api_gateway_url | URL of API Gateway web app |
| hr_doc_manager_app_id | Application ID of HR Doc Manager |
| hr_doc_manager_object_id | Object ID of HR Doc Manager |
| hr_doc_manager_url | URL of HR Doc Manager web app |
