# Applications Module - Main Configuration
# This module deploys deceptive applications including a fake login portal and SQL database

# Random string for unique names
resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

# App Service Plan for Deceptive Portal
resource "azurerm_service_plan" "deceptive_portal" {
  name                = "asp-${random_string.unique.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type            = "Windows"
  sku_name           = "B1"  # Basic tier for cost efficiency
}

# Storage account for portal deployment package
resource "azurerm_storage_account" "portal_deployment" {
  name                     = "portal${random_string.unique.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
}

# Storage container for portal deployment package
resource "azurerm_storage_container" "portal_deployment" {
  name                  = "portal-deployment"
  storage_account_name  = azurerm_storage_account.portal_deployment.name
  container_access_type = "private"
}

# Create ZIP package of portal files
data "archive_file" "portal_package" {
  type        = "zip"
  source_dir  = "${path.module}/portal"
  output_path = "${path.module}/portal.zip"
}

# Upload portal package to storage
resource "azurerm_storage_blob" "portal_package" {
  name                   = "portal-${filesha256(data.archive_file.portal_package.output_path)}.zip"
  storage_account_name   = azurerm_storage_account.portal_deployment.name
  storage_container_name = azurerm_storage_container.portal_deployment.name
  type                  = "Block"
  source               = data.archive_file.portal_package.output_path
}

# Generate SAS URL for the portal package
data "azurerm_storage_account_blob_container_sas" "portal_package" {
  connection_string = azurerm_storage_account.portal_deployment.primary_connection_string
  container_name    = azurerm_storage_container.portal_deployment.name
  
  start  = timestamp()
  expiry = timeadd(timestamp(), "8760h") # 1 year

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

# App Service for Deceptive Portal
resource "azurerm_windows_web_app" "deceptive_portal" {
  name                = "portal-${random_string.unique.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.deceptive_portal.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      current_stack = "node"
      node_version = "~16"
    }
    always_on = true
    websockets_enabled = false
    http2_enabled = true
    minimum_tls_version = "1.2"
    default_documents = ["index.html"]

    # Enable static file serving
    virtual_application {
      physical_path = "site\\wwwroot"
      preload = true
      virtual_path = "/"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE" = "true"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
  }

  # Deploy zip package directly
  zip_deploy_file = data.archive_file.portal_package.output_path
}

# Azure SQL Server (Intentionally Public)
resource "azurerm_mssql_server" "deceptive" {
  name                         = "sql-${random_string.unique.result}"
  location                     = var.location
  resource_group_name         = var.resource_group_name
  version                     = "12.0"
  administrator_login         = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  # Intentionally public for deception
  public_network_access_enabled = true
  minimum_tls_version          = "1.2"
}

# Azure SQL Database
resource "azurerm_mssql_database" "deceptive" {
  name      = "honeypot-db"
  server_id = azurerm_mssql_server.deceptive.id
  sku_name  = "Basic"
}

# Store SQL credentials in Key Vault (matching the pattern from identity module)
resource "azurerm_key_vault_secret" "sql_admin_creds" {
  name         = "sql-server-admin-credentials"
  value        = jsonencode({
    server_name = azurerm_mssql_server.deceptive.fully_qualified_domain_name
    username    = var.sql_admin_username
    password    = var.sql_admin_password
    database    = azurerm_mssql_database.deceptive.name
  })
  content_type = "application/json"
  key_vault_id = var.key_vault_id
}


locals {
  # Since we know the honey users are passed from the root module
  honey_users = var.honey_users
}


# Wait for database to be ready
resource "time_sleep" "wait_for_db" {
  depends_on = [azurerm_mssql_database.deceptive]
  create_duration = "30s"
}

# Set up the database schema and data
resource "null_resource" "setup_database" {
  depends_on = [
    azurerm_mssql_database.deceptive,
    azurerm_mssql_firewall_rule.allow_all,
    time_sleep.wait_for_db
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      # Install SqlServer module if not present
      if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Host "Installing SqlServer module..."
        Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
      }

      $server = "${azurerm_mssql_server.deceptive.fully_qualified_domain_name}"
      $database = "${azurerm_mssql_database.deceptive.name}"
      $username = "${var.sql_admin_username}"
      $password = "${var.sql_admin_password}"
      $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
      $credentials = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

      Write-Host "Creating tables..."
      $createTablesQuery = @"
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='employeesSensitive' AND xtype='U')
      BEGIN
        CREATE TABLE employeesSensitive (
          id INT IDENTITY(1,1) PRIMARY KEY,
          username NVARCHAR(255) NOT NULL UNIQUE,
          email NVARCHAR(255) NOT NULL,
          password NVARCHAR(255) NOT NULL,
          department NVARCHAR(100),
          job_title NVARCHAR(100),
          is_active BIT DEFAULT 1
        );
      END

      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='invoices' AND xtype='U')
      BEGIN
        CREATE TABLE invoices (
          invoice_id INT IDENTITY(1,1) PRIMARY KEY,
          client_name NVARCHAR(255),
          amount DECIMAL(18,2),
          due_date DATE,
          status NVARCHAR(50) DEFAULT 'Pending',
          reference_code NVARCHAR(50) UNIQUE
        );
      END   
 
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='payroll' AND xtype='U')
      BEGIN
        CREATE TABLE payroll (
          payroll_id INT IDENTITY(1,1) PRIMARY KEY,
          employee_id INT FOREIGN KEY REFERENCES employeesSensitive(id),
          base_salary DECIMAL(10,2) NOT NULL,
          bonus DECIMAL(10,2) DEFAULT 0,
          deductions DECIMAL(10,2) DEFAULT 0,
          net_pay DECIMAL(10,2) NOT NULL,
          pay_date DATE NOT NULL
        );
      END
"@

      Invoke-Sqlcmd -ServerInstance $server -Database $database -Credential $credentials -Query $createTablesQuery -QueryTimeout 120

      Write-Host "Inserting data..."
      ${join("\n      ", [for u in var.honey_users : 
        "$insertQuery = \"IF NOT EXISTS (SELECT 1 FROM employeesSensitive WHERE username = '${u.username}') INSERT INTO employeesSensitive (username, email, password, department, job_title) VALUES ('${u.username}', '${u.email}', '${u.password}', '${u.department}', '${u.job_title}');\"\n      Invoke-Sqlcmd -ServerInstance $server -Database $database -Credential $credentials -Query $insertQuery -QueryTimeout 30"
      ])}

      Write-Host "Inserting sample invoices..."
      $insertInvoicesQuery = @"
      IF NOT EXISTS (SELECT 1 FROM invoices WHERE reference_code = 'INV-2025-001')
      BEGIN
        INSERT INTO invoices (client_name, amount, due_date, status, reference_code)
        VALUES 
        ('Contoso Ltd.', 15000.00, '2025-09-30', 'Pending', 'INV-2025-001'),
        ('Fabrikam Inc.', 8500.50, '2025-10-15', 'Paid', 'INV-2025-002'),
        ('Woodgrove Bank', 22000.00, '2025-09-15', 'Overdue', 'INV-2025-003'),
        ('Tailwind Traders', 12750.75, '2025-11-01', 'Pending', 'INV-2025-004');
      END
"@
      Invoke-Sqlcmd -ServerInstance $server -Database $database -Credential $credentials -Query $insertInvoicesQuery -QueryTimeout 30

      Write-Host "Inserting sample payroll data..."
      $insertPayrollQuery = @"
      IF EXISTS (SELECT 1 FROM employeesSensitive)
      BEGIN
        INSERT INTO payroll (employee_id, base_salary, bonus, deductions, net_pay, pay_date)
        SELECT TOP 4
          id as employee_id,
          CASE 
            WHEN job_title LIKE '%Manager%' THEN 85000.00
            WHEN job_title LIKE '%Senior%' THEN 75000.00
            ELSE 65000.00
          END as base_salary,
          5000.00 as bonus,
          2500.00 as deductions,
          CASE 
            WHEN job_title LIKE '%Manager%' THEN 87500.00
            WHEN job_title LIKE '%Senior%' THEN 77500.00
            ELSE 67500.00
          END as net_pay,
          '2025-08-31' as pay_date
        FROM employeesSensitive
        WHERE NOT EXISTS (
          SELECT 1 FROM payroll p WHERE p.employee_id = employeesSensitive.id
        );
      END
"@
      Invoke-Sqlcmd -ServerInstance $server -Database $database -Credential $credentials -Query $insertPayrollQuery -QueryTimeout 30

      Write-Host "Database setup completed successfully!"
    EOT
  }

  triggers = {
    database_id = azurerm_mssql_database.deceptive.id
    user_count  = var.honey_user_count
    honey_users = jsonencode(var.honey_users)
    server_name = azurerm_mssql_server.deceptive.name
    firewall_rules = "${azurerm_mssql_firewall_rule.allow_all.id}${azurerm_mssql_firewall_rule.allow_azure_portal.id}"
  }
}






# Firewall rule to allow Azure Portal access
resource "azurerm_mssql_firewall_rule" "allow_azure_portal" {
  name             = "AllowAzurePortal"
  server_id        = azurerm_mssql_server.deceptive.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"  # Special case to allow Azure Services
}

# Firewall rule to allow all IPs (intentionally vulnerable)
resource "azurerm_mssql_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_mssql_server.deceptive.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
