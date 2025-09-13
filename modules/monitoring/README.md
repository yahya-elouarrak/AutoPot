# AutoPot Monitoring Module

This module provides comprehensive security monitoring for the AutoPot honeypot infrastructure with Microsoft Sentinel integration and Slack notifications.

## Features

### 🔍 **Comprehensive Monitoring**
- **Azure AD Sign-in Monitoring**: Detects any sign-in attempts to honey user accounts
- **SQL Server Access Monitoring**: Tracks all access attempts to the intentionally vulnerable SQL database
- **Key Vault Access Monitoring**: Monitors access to stored honeypot credentials
- **Web Portal Monitoring**: Detects suspicious access patterns to the deceptive web portal
- **Privilege Escalation Detection**: Identifies attempts to escalate privileges in the honeypot environment

### 🚨 **Microsoft Sentinel Integration**
- **Automated Analytics Rules**: Pre-configured detection rules for common attack patterns
- **Incident Management**: Automatic incident creation and classification
- **MITRE ATT&CK Mapping**: Rules mapped to relevant tactics and techniques
- **Customizable Severity Levels**: Critical, High, Medium, and Low severity classifications

### 📱 **Slack Notifications**
- **Real-time Alerts**: Immediate notifications for security incidents
- **Rich Formatting**: Color-coded messages based on severity levels
- **Detailed Context**: Includes IP addresses, user agents, timestamps, and event details
- **Automated Response**: Logic Apps trigger Function Apps for seamless notification delivery

### ⚡ **Azure Functions**
- **Slack Notifier**: HTTP-triggered function for processing Sentinel incidents
- **Security Monitor**: Timer-triggered function running every 5 minutes for proactive monitoring
- **Custom Queries**: Advanced KQL queries for detecting sophisticated attack patterns

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Honeypot      │    │   Log Analytics  │    │   Microsoft     │
│   Resources     │───▶│   Workspace      │───▶│   Sentinel      │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│     Slack       │◀───│   Azure          │◀───│   Logic Apps    │
│   Notifications │    │   Functions      │    │   Automation    │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Monitored Resources

### 🔐 **Identity Resources**
- Honey user accounts with realistic profiles
- Azure AD group memberships
- Sign-in attempts and authentication events

### 🗄️ **Application Resources**
- SQL Server with intentionally weak credentials
- SQL Database with sensitive tables (employees, payroll, invoices)
- Web portal with login functionality
- Storage accounts and deployment artifacts

### 🔑 **Infrastructure Resources**
- Key Vault containing honeypot credentials
- Resource group and subscription-level activities
- Network access patterns and anomalies

## Detection Rules

### 🎯 **Honey User Sign-in Detection**
- **Trigger**: Any sign-in attempt to honey user accounts
- **Severity**: Critical (successful) / High (failed)
- **Frequency**: Every 5 minutes
- **MITRE**: T1078 (Valid Accounts), T1110 (Brute Force)

### 🗃️ **SQL Server Suspicious Access**
- **Trigger**: Login attempts, database access, schema queries
- **Severity**: Critical (successful login) / High (failed attempts)
- **Frequency**: Every 10 minutes
- **MITRE**: T1078 (Valid Accounts), T1082 (System Information Discovery)

### 🔐 **Key Vault Access Monitoring**
- **Trigger**: Secret retrieval, listing, modification, or deletion
- **Severity**: Critical (modification/deletion) / High (access)
- **Frequency**: Every 15 minutes
- **MITRE**: T1555 (Credentials from Password Stores), T1087 (Account Discovery)

### 🌐 **Web Portal Activity**
- **Trigger**: Multiple requests, admin page access, form submissions
- **Severity**: High (admin access) / Medium (suspicious patterns)
- **Frequency**: Every 10 minutes
- **MITRE**: T1190 (Exploit Public-Facing Application), T1083 (File and Directory Discovery)

### ⬆️ **Privilege Escalation**
- **Trigger**: Role assignments, privilege grants, permission changes
- **Severity**: Critical
- **Frequency**: Every 5 minutes
- **MITRE**: T1078 (Valid Accounts), T1484 (Domain Policy Modification)

## Configuration

### Required Variables
```hcl
variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
}
```

### Environment Variables (Function App)
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications
- `LOG_ANALYTICS_WORKSPACE_ID`: Workspace ID for queries
- `LOG_ANALYTICS_WORKSPACE_KEY`: Workspace key for authentication
- `KEYVAULT_URI`: Key Vault URI for credential access
- `SQL_SERVER_NAME`: SQL Server name for monitoring
- `RESOURCE_GROUP_NAME`: Resource group name
- `SUBSCRIPTION_ID`: Azure subscription ID

## Deployment

1. **Configure Slack Webhook**:
   ```bash
   export TF_VAR_slack_webhook_url="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
   ```

2. **Deploy with Terraform**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Verify Deployment**:
   - Check Log Analytics workspace creation
   - Verify Sentinel onboarding
   - Test Function App deployment
   - Confirm Logic Apps automation rules

## Monitoring Dashboard

The module creates a comprehensive monitoring setup with:

- **Log Analytics Workspace**: Centralized logging for all resources
- **Application Insights**: Function App performance monitoring
- **Diagnostic Settings**: Automatic log collection from all honeypot resources
- **Sentinel Analytics Rules**: 5 pre-configured detection rules
- **Automation Rules**: Automatic incident response and notification

## Security Considerations

- All Function App code uses managed identities for authentication
- Slack webhook URL is stored as a sensitive variable
- Log retention is set to 90 days for compliance
- Role-based access control (RBAC) is enforced for all monitoring components
- Diagnostic logs are automatically encrypted at rest

## Troubleshooting

### Common Issues

1. **Function App Not Receiving Triggers**:
   - Verify Logic Apps have correct permissions
   - Check Function App keys and authentication
   - Review Logic Apps run history

2. **Slack Notifications Not Working**:
   - Validate webhook URL format
   - Check Function App logs for errors
   - Verify network connectivity

3. **Sentinel Rules Not Firing**:
   - Confirm data ingestion in Log Analytics
   - Check rule query syntax and frequency
   - Verify diagnostic settings are enabled

### Monitoring Health

- Function App logs are available in Application Insights
- Logic Apps execution history shows automation status
- Sentinel incidents appear in the Security portal
- Log Analytics queries can validate data ingestion

## Cost Optimization

- Function Apps use Consumption plan (pay-per-execution)
- Log Analytics uses Pay-as-you-go pricing
- Diagnostic settings only collect essential security logs
- Retention period is optimized for security requirements

## Support

For issues or questions regarding the monitoring module:
1. Check Function App logs in Application Insights
2. Review Sentinel incident details
3. Validate Log Analytics data ingestion
4. Test Slack webhook connectivity manually
