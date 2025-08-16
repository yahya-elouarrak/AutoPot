output "admin_portal_app_id" {
  description = "The Application ID of the Admin Portal"
  value       = azuread_application.admin_portal.application_id
}

output "admin_portal_object_id" {
  description = "The Object ID of the Admin Portal"
  value       = azuread_application.admin_portal.object_id
}

output "admin_portal_url" {
  description = "The URL of the Admin Portal web app"
  value       = "https://${azurerm_linux_web_app.admin_portal.name}.azurewebsites.net"
}

output "api_gateway_app_id" {
  description = "The Application ID of the Internal API Gateway"
  value       = azuread_application.api_gateway.application_id
}

output "api_gateway_object_id" {
  description = "The Object ID of the Internal API Gateway"
  value       = azuread_application.api_gateway.object_id
}

output "api_gateway_url" {
  description = "The URL of the API Gateway web app"
  value       = "https://${azurerm_linux_web_app.api_gateway.name}.azurewebsites.net"
}

output "hr_doc_manager_app_id" {
  description = "The Application ID of the HR Document Manager"
  value       = azuread_application.hr_doc_manager.application_id
}

output "hr_doc_manager_object_id" {
  description = "The Object ID of the HR Document Manager"
  value       = azuread_application.hr_doc_manager.object_id
}

output "hr_doc_manager_url" {
  description = "The URL of the HR Document Manager web app"
  value       = "https://${azurerm_linux_web_app.hr_doc_manager.name}.azurewebsites.net"
}
