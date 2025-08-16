# Azure AD Applications Module


# Admin Portal Backend
resource "azuread_application" "admin_portal" {
  display_name     = "${var.admin_portal_name}-${var.environment}"
  identifier_uris  = ["api://${var.admin_portal_name}-${var.environment}"]
  sign_in_audience = "AzureADMyOrg"

  web {
    homepage_url  = "https://${var.admin_portal_name}-${var.environment}.azurewebsites.net"
    redirect_uris = ["https://${var.admin_portal_name}-${var.environment}.azurewebsites.net/oauth2/callback"]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "admin_portal" {
  application_id = azuread_application.admin_portal.application_id
  tags          = ["HoneyPot", "AdminPortal"]
}

resource "azurerm_service_plan" "admin_portal" {
  name                = "${var.admin_portal_name}-plan-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type            = "Linux"
  sku_name           = var.admin_portal_sku
}

resource "azurerm_linux_web_app" "admin_portal" {
  name                = "${var.admin_portal_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.admin_portal.id
  
  site_config {
    always_on = true
    application_stack {
      node_version = "18-lts"
    }
  }

  auth_settings {
    enabled                       = true
    default_provider             = "AzureActiveDirectory"
    unauthenticated_client_action = "RedirectToLoginPage"

    active_directory {
      client_id = azuread_application.admin_portal.application_id
    }
  }

}

# Internal API Gateway
resource "azuread_application" "api_gateway" {
  display_name     = "${var.api_gateway_name}-${var.environment}"
  identifier_uris  = ["api://${var.api_gateway_name}-${var.environment}"]
  sign_in_audience = "AzureADMyOrg"

  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access the API on behalf of signed-in users"
      admin_consent_display_name = "Access API"
      enabled                   = true
      id                        = "6eedf186-f1a1-4622-8534-6f9f24689c99"
      type                      = "User"
      user_consent_description  = "Allow access to API"
      user_consent_display_name = "Access API"
      value                    = "user_impersonation"
    }
  }
}

resource "azuread_service_principal" "api_gateway" {
  application_id = azuread_application.api_gateway.application_id
  #tags
}

resource "azurerm_service_plan" "api_gateway" {
  name                = "${var.api_gateway_name}-plan-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type            = "Linux"
  sku_name           = var.api_gateway_sku

}

resource "azurerm_linux_web_app" "api_gateway" {
  name                = "${var.api_gateway_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.api_gateway.id

  site_config {
    always_on = true
    application_stack {
      node_version = "18-lts"
    }
  }

  auth_settings {
    enabled                       = true
    default_provider             = "AzureActiveDirectory"
    unauthenticated_client_action = "RedirectToLoginPage"

    active_directory {
      client_id = azuread_application.api_gateway.application_id
    }
  }

}

# HR Document Manager
resource "azuread_application" "hr_doc_manager" {
  display_name     = "${var.hr_doc_manager_name}-${var.environment}"
  identifier_uris  = ["api://${var.hr_doc_manager_name}-${var.environment}"]
  sign_in_audience = "AzureADMyOrg"

  web {
    homepage_url  = "https://${var.hr_doc_manager_name}-${var.environment}.azurewebsites.net"
    redirect_uris = ["https://${var.hr_doc_manager_name}-${var.environment}.azurewebsites.net/auth/callback"]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "hr_doc_manager" {
  application_id = azuread_application.hr_doc_manager.application_id

}

resource "azurerm_service_plan" "hr_doc_manager" {
  name                = "${var.hr_doc_manager_name}-plan-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type            = "Linux"
  sku_name           = var.hr_doc_manager_sku

}

resource "azurerm_linux_web_app" "hr_doc_manager" {
  name                = "${var.hr_doc_manager_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.hr_doc_manager.id

  site_config {
    always_on = true
    application_stack {
      node_version = "18-lts"
    }
  }

  auth_settings {
    enabled                       = true
    default_provider             = "AzureActiveDirectory"
    unauthenticated_client_action = "RedirectToLoginPage"

    active_directory {
      client_id = azuread_application.hr_doc_manager.application_id
    }
  }

}