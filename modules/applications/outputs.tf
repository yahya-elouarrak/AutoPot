# Outputs for the applications module

output "app_service_url" {
  description = "The URL of the deceptive portal"
  value       = "https://${azurerm_windows_web_app.deceptive_portal.default_hostname}"
}

output "app_service_id" {
  description = "The ID of the App Service"
  value       = azurerm_windows_web_app.deceptive_portal.id
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.deceptive.fully_qualified_domain_name
}

output "sql_server_id" {
  description = "The ID of the SQL server"
  value       = azurerm_mssql_server.deceptive.id
}

output "sql_server_name" {
  description = "The name of the SQL server"
  value       = azurerm_mssql_server.deceptive.name
}

output "sql_database_name" {
  description = "The name of the SQL database"
  value       = azurerm_mssql_database.deceptive.name
}

output "sql_database_id" {
  description = "The ID of the SQL database"
  value       = azurerm_mssql_database.deceptive.id
}
