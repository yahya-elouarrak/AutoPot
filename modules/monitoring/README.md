# Monitoring Module

This module sets up centralized monitoring and alerting for the AutoPot deception infrastructure. It aggregates logs from decoy identities and applications, applies detection logic using KQL queries, and sends alerts to Slack.

## Features

- Creates a dedicated Log Analytics workspace
- Configures diagnostic settings for Azure AD logs
- Implements KQL-based detection rules for:
  - Honey user sign-in attempts
  - Decoy application access
  - Suspicious IP addresses
- Integrates with Slack for real-time alerting
- Supports customizable alert thresholds and retention periods

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name        = "your-resource-group"
  location                   = "francecentral"
  environment               = "dev"
  project_name              = "autopot"
  
  # Key Vault reference for Slack webhook
  slack_webhook_key_vault_id = azurerm_key_vault.main.id
  
  # Optional: customize alert settings
  alert_severity    = 1  # Error
  alert_frequency   = 5  # minutes
  alert_time_window = 5  # minutes
  
  # Optional: adjust log retention
  retention_in_days = 90
  
  # Additional tags
  tags = {
    Owner = "Security Team"
  }
}
```

## Requirements

- Azure subscription
- Azure AD tenant with admin rights
- Terraform >= 1.0
- AzureRM provider >= 3.0
- Slack webhook URL stored in Key Vault

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | string | n/a | yes |
| location | Azure region for resources | string | n/a | yes |
| environment | Environment name for tagging | string | n/a | yes |
| project_name | Project name for tagging | string | n/a | yes |
| slack_webhook_key_vault_id | Key Vault ID containing Slack webhook | string | n/a | yes |
| slack_webhook_secret_name | Key Vault secret name for webhook | string | "slack-webhook-url" | no |
| workspace_name | Log Analytics workspace name | string | "autopot-logs" | no |
| retention_in_days | Log retention period | number | 30 | no |
| alert_severity | Alert severity level (0-4) | number | 1 | no |
| alert_frequency | Alert check frequency (minutes) | number | 5 | no |
| alert_time_window | Alert time window (minutes) | number | 5 | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| workspace_id | Log Analytics workspace ID |
| workspace_name | Log Analytics workspace name |
| workspace_key | Workspace primary shared key |
| action_group_id | Slack action group ID |
| alert_rule_ids | Map of alert rule IDs |

## Alert Rules

### Honey User Sign-ins
Detects authentication attempts against honey user accounts:
- Triggers on failed sign-in attempts
- Captures IP address and location
- Includes result descriptions

### Decoy App Access
Monitors access to decoy applications:
- Tracks operations against tagged resources
- Records initiated identity
- Captures full audit context

### Suspicious IP Detection
Identifies potentially malicious sources:
- Excludes private IP ranges
- Uses frequency-based threshold
- Correlates across sign-in and audit logs
