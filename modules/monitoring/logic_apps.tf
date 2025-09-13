# Logic Apps for automated incident response and Slack notifications

# Logic App for Sentinel incident automation
resource "azurerm_logic_app_workflow" "sentinel_incident_response" {
  name                = "la-sentinel-incident-${random_string.monitoring_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "monitoring"
    Purpose     = "honeypot-security"
  }
}

# Logic App trigger for Sentinel incidents
resource "azurerm_logic_app_trigger_http_request" "sentinel_incident_trigger" {
  name         = "sentinel-incident-trigger"
  logic_app_id = azurerm_logic_app_workflow.sentinel_incident_response.id

  schema = jsonencode({
    type = "object"
    properties = {
      WorkspaceId = {
        type = "string"
      }
      AlertRuleId = {
        type = "string"
      }
      DisplayName = {
        type = "string"
      }
      Description = {
        type = "string"
      }
      Severity = {
        type = "string"
      }
      Status = {
        type = "string"
      }
      TimeGenerated = {
        type = "string"
      }
      IncidentNumber = {
        type = "string"
      }
      Entities = {
        type = "array"
      }
    }
  })
}

# Logic App action to call Function App for Slack notification
resource "azurerm_logic_app_action_http" "call_slack_function" {
  name         = "call-slack-function"
  logic_app_id = azurerm_logic_app_workflow.sentinel_incident_response.id
  method       = "POST"
  uri          = "https://${azurerm_linux_function_app.monitoring_functions.default_hostname}/api/slack_notifier"

  headers = {
    "Content-Type" = "application/json"
    "x-functions-key" = "@listKeys('${azurerm_linux_function_app.monitoring_functions.id}/host/default', '2022-03-01').functionKeys.default"
  }

  body = jsonencode({
    WorkspaceId     = "@triggerBody()?['WorkspaceId']"
    AlertRuleId     = "@triggerBody()?['AlertRuleId']"
    DisplayName     = "@triggerBody()?['DisplayName']"
    Description     = "@triggerBody()?['Description']"
    Severity        = "@triggerBody()?['Severity']"
    Status          = "@triggerBody()?['Status']"
    TimeGenerated   = "@triggerBody()?['TimeGenerated']"
    IncidentNumber  = "@triggerBody()?['IncidentNumber']"
    Entities        = "@triggerBody()?['Entities']"
  })

  depends_on = [azurerm_logic_app_trigger_http_request.sentinel_incident_trigger]
}

# Sentinel automation rule to trigger Logic App
resource "azurerm_sentinel_automation_rule" "incident_notification" {
  name                       = "AutoPot-IncidentNotification"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autopot_monitoring.id
  display_name              = "AutoPot Incident Slack Notification"
  order                     = 1
  enabled                   = true

  condition {
    property = "IncidentSeverity"
    operator = "Equals"
    values   = ["High", "Medium", "Low"]
  }

  action_incident {
    order  = 1
    status = "Active"
  }

  action_playbook {
    order        = 2
    logic_app_id = azurerm_logic_app_workflow.sentinel_incident_response.id
    tenant_id    = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [
    azurerm_logic_app_workflow.sentinel_incident_response,
    azurerm_sentinel_alert_rule_scheduled.honey_user_signin,
    azurerm_sentinel_alert_rule_scheduled.sql_server_suspicious_access,
    azurerm_sentinel_alert_rule_scheduled.keyvault_suspicious_access,
    azurerm_sentinel_alert_rule_scheduled.web_portal_suspicious_access,
    azurerm_sentinel_alert_rule_scheduled.privilege_escalation
  ]
}

# Role assignment for Logic App to execute Function App
resource "azurerm_role_assignment" "logic_app_function_invoker" {
  scope                = azurerm_linux_function_app.monitoring_functions.id
  role_definition_name = "Website Contributor"
  principal_id         = azurerm_logic_app_workflow.sentinel_incident_response.identity[0].principal_id
}

