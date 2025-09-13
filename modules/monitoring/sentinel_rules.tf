# Sentinel Analytics Rules for AutoPot Honeypot Monitoring

# Analytics rule for honey user sign-in attempts
resource "azurerm_sentinel_alert_rule_scheduled" "honey_user_signin" {
  name                       = "AutoPot-HoneyUserSignIn"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id
  display_name              = "Honey User Sign-in Detected"
  description               = "Detects sign-in attempts to honeypot user accounts"
  severity                  = "High"
  enabled                   = true
  
  query_frequency   = "PT5M"  # Every 5 minutes
  query_period     = "PT5M"
  trigger_threshold = 1
  
  query = <<-EOT
    SigninLogs
    | where UserPrincipalName in (${join(", ", [for user in var.honey_users : "\"${user.email}\""])})
    | where ResultType == "0" or ResultType != "0"  // Both successful and failed attempts
    | extend
        SuspiciousActivity = "Honey User Sign-in Attempt",
        HoneyUser = UserPrincipalName,
        SourceIP = IPAddress,
        UserAgent = UserAgent,
        Location = Location,
        RiskLevel = case(
            ResultType == "0", "CRITICAL - Successful honey user login",
            "HIGH - Failed honey user login attempt"
        )
    | project
        TimeGenerated,
        SuspiciousActivity,
        HoneyUser,
        SourceIP,
        UserAgent,
        Location,
        RiskLevel,
        ResultType,
        ResultDescription
  EOT

  tactics = ["InitialAccess", "CredentialAccess"]
  techniques = ["T1078", "T1110"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled = true
      reopen_closed_incidents = false
      lookback_duration = "PT5H"
      entity_matching_method = "AllEntities"
    }
  }
}

# Analytics rule for suspicious SQL Server access
resource "azurerm_sentinel_alert_rule_scheduled" "sql_server_suspicious_access" {
  name                       = "AutoPot-SQLSuspiciousAccess"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id
  display_name              = "Suspicious SQL Server Access"
  description               = "Detects suspicious access patterns to honeypot SQL Server"
  severity                  = "High"
  enabled                   = true
  
  query_frequency   = "PT10M"  # Every 10 minutes
  query_period     = "PT10M"
  trigger_threshold = 1
  
  query = <<-EOT
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.SQL"
    | where Category == "SQLSecurityAuditEvents"
    | where server_name_s contains "${var.sql_server_name}"
    | where action_name_s in ("LOGIN", "LOGOUT", "DATABASE_OBJECT_ACCESS_GROUP", "SCHEMA_OBJECT_ACCESS_GROUP")
    | extend
        SuspiciousActivity = case(
            action_name_s == "LOGIN", "SQL Server Login Attempt",
            action_name_s == "DATABASE_OBJECT_ACCESS_GROUP", "Database Object Access",
            action_name_s == "SCHEMA_OBJECT_ACCESS_GROUP", "Schema Object Access",
            "SQL Server Activity"
        ),
        SourceIP = client_ip_s,
        DatabaseName = database_name_s,
        Username = server_principal_name_s,
        RiskLevel = case(
            succeeded_s == "true" and action_name_s == "LOGIN", "CRITICAL - Successful SQL login to honeypot",
            succeeded_s == "false" and action_name_s == "LOGIN", "HIGH - Failed SQL login attempt",
            action_name_s contains "ACCESS", "MEDIUM - Database access attempt",
            "LOW - General SQL activity"
        )
    | project
        TimeGenerated,
        SuspiciousActivity,
        SourceIP,
        DatabaseName,
        Username,
        RiskLevel,
        action_name_s,
        succeeded_s,
        statement_s
  EOT

  tactics = ["InitialAccess", "Discovery", "Collection"]
  techniques = ["T1078", "T1082", "T1005"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled = true
      reopen_closed_incidents = false
      lookback_duration = "PT1H"
      entity_matching_method = "AllEntities"
    }
  }
}

# Analytics rule for Key Vault access monitoring
resource "azurerm_sentinel_alert_rule_scheduled" "keyvault_suspicious_access" {
  name                       = "AutoPot-KeyVaultAccess"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id
  display_name              = "Key Vault Suspicious Access"
  description               = "Detects suspicious access to honeypot Key Vault secrets"
  severity                  = "Medium"
  enabled                   = true
  
  query_frequency   = "PT15M"  # Every 15 minutes
  query_period     = "PT15M"
  trigger_threshold = 1
  
  query = <<-EOT
    KeyVaultData
    | where OperationName in ("SecretGet", "SecretList", "SecretSet", "SecretDelete")
    | where ResourceId contains "kvtest62"  // Key vault name pattern
    | extend
        SuspiciousActivity = case(
            OperationName == "SecretGet", "Key Vault Secret Retrieved",
            OperationName == "SecretList", "Key Vault Secrets Listed",
            OperationName == "SecretSet", "Key Vault Secret Modified",
            OperationName == "SecretDelete", "Key Vault Secret Deleted",
            "Key Vault Activity"
        ),
        SourceIP = CallerIpAddress,
        Identity = identity_claim_appid_g,
        SecretName = id_s,
        RiskLevel = case(
            OperationName == "SecretGet" and ResultSignature == "OK", "HIGH - Honeypot secret accessed",
            OperationName == "SecretList" and ResultSignature == "OK", "MEDIUM - Honeypot secrets enumerated",
            OperationName in ("SecretSet", "SecretDelete"), "CRITICAL - Honeypot secret modified/deleted",
            "LOW - Key Vault access attempt"
        )
    | project
        TimeGenerated,
        SuspiciousActivity,
        SourceIP,
        Identity,
        SecretName,
        RiskLevel,
        OperationName,
        ResultSignature,
        ResultDescription
  EOT

  tactics = ["CredentialAccess", "Discovery"]
  techniques = ["T1555", "T1087"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled = true
      reopen_closed_incidents = false
      lookback_duration = "PT30M"
      entity_matching_method = "AllEntities"
    }
  }
}

# Analytics rule for web portal suspicious access
resource "azurerm_sentinel_alert_rule_scheduled" "web_portal_suspicious_access" {
  name                       = "AutoPot-WebPortalAccess"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id
  display_name              = "Web Portal Suspicious Access"
  description               = "Detects suspicious access patterns to honeypot web portal"
  severity                  = "Medium"
  enabled                   = true
  
  query_frequency   = "PT10M"  # Every 10 minutes
  query_period     = "PT10M"
  trigger_threshold = 3  # Trigger after 3 requests
  
  query = <<-EOT
    AppServiceHTTPLogs
    | where CsHost contains "portal-"  // App service name pattern
    | where ScStatus in (200, 401, 403, 404, 500)
    | extend
        SuspiciousActivity = case(
            CsUriStem contains "login", "Login Page Access",
            CsUriStem contains "admin", "Admin Page Access Attempt",
            CsMethod == "POST", "Form Submission Attempt",
            "Web Portal Access"
        ),
        SourceIP = CIp,
        UserAgent = CsUserAgent,
        RequestPath = CsUriStem,
        StatusCode = ScStatus,
        RiskLevel = case(
            CsUriStem contains "admin" and ScStatus == 200, "HIGH - Admin page accessed",
            CsUriStem contains "login" and CsMethod == "POST", "MEDIUM - Login attempt",
            ScStatus == 200, "LOW - Successful page access",
            "LOW - Web request"
        )
    | summarize
        RequestCount = count(),
        UniquePages = dcount(CsUriStem),
        StatusCodes = make_set(ScStatus)
        by SourceIP, UserAgent, bin(TimeGenerated, 5m)
    | where RequestCount >= 3  // Multiple requests in 5 minutes
    | extend
        SuspiciousActivity = "Multiple Web Portal Requests",
        RiskLevel = case(
            RequestCount >= 10, "HIGH - Potential scanning/brute force",
            RequestCount >= 5, "MEDIUM - Suspicious activity pattern",
            "LOW - Multiple requests"
        )
    | project
        TimeGenerated,
        SuspiciousActivity,
        SourceIP,
        UserAgent,
        RequestCount,
        UniquePages,
        StatusCodes,
        RiskLevel
  EOT

  tactics = ["InitialAccess", "Discovery"]
  techniques = ["T1190", "T1083"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled = true
      reopen_closed_incidents = false
      lookback_duration = "PT1H"
      entity_matching_method = "AllEntities"
    }
  }
}

# Analytics rule for privilege escalation attempts
resource "azurerm_sentinel_alert_rule_scheduled" "privilege_escalation" {
  name                       = "AutoPot-PrivilegeEscalation"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id
  display_name              = "Privilege Escalation Attempt"
  description               = "Detects potential privilege escalation attempts in honeypot environment"
  severity                  = "High"
  enabled                   = true
  
  query_frequency   = "PT5M"  # Every 5 minutes
  query_period     = "PT5M"
  trigger_threshold = 1
  
  query = <<-EOT
    union
    (
        // Azure AD role assignments
        AuditLogs
        | where OperationName in ("Add member to role", "Add eligible member to role", "Activate role")
        | where TargetResources has_any (${join(", ", [for user in var.honey_users : "\"${user.object_id}\""])})
        | extend
            SuspiciousActivity = "Azure AD Role Assignment to Honey User",
            TargetUser = tostring(TargetResources[0].userPrincipalName),
            RiskLevel = "CRITICAL - Privilege escalation detected"
    ),
    (
        // SQL Server role changes
        AzureDiagnostics
        | where ResourceProvider == "MICROSOFT.SQL"
        | where Category == "SQLSecurityAuditEvents"
        | where statement_s contains "ALTER ROLE" or statement_s contains "GRANT"
        | extend
            SuspiciousActivity = "SQL Server Privilege Grant",
            TargetUser = server_principal_name_s,
            RiskLevel = "HIGH - SQL privilege escalation"
    )
    | project
        TimeGenerated,
        SuspiciousActivity,
        TargetUser,
        RiskLevel,
        OperationName,
        InitiatedBy = tostring(InitiatedBy.user.userPrincipalName),
        AdditionalDetails
  EOT

  tactics = ["PrivilegeEscalation", "Persistence"]
  techniques = ["T1078", "T1484"]

  incident_configuration {
    create_incident = true
    grouping {
      enabled = true
      reopen_closed_incidents = false
      lookback_duration = "PT2H"
      entity_matching_method = "AllEntities"
    }
  }
}
