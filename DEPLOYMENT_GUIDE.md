# AutoPot Deployment Guide

This guide walks you through deploying the AutoPot honeypot infrastructure with comprehensive monitoring and Slack notifications.

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** v1.0+ installed
3. **PowerShell** (for SQL database setup)
4. **Slack Workspace** with webhook configured

## Step 1: Configure Slack Integration

1. Create a Slack app in your workspace:
   - Go to https://api.slack.com/apps
   - Click "Create New App" → "From scratch"
   - Name it "AutoPot Security Monitor"

2. Enable Incoming Webhooks:
   - Go to "Incoming Webhooks" in your app settings
   - Toggle "Activate Incoming Webhooks" to On
   - Click "Add New Webhook to Workspace"
   - Select the channel for security alerts
   - Copy the webhook URL (starts with `https://hooks.slack.com/services/`)

## Step 2: Configure Terraform Variables

1. Copy the example variables file:
   ```powershell
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   # Project configuration
   project_name = "autopot"
   environment  = "dev"
   location     = "francecentral"  # Change to your preferred region
   resource_group_name = "rg-autopot"

   # Number of honey user accounts (3-5 recommended)
   honey_user_count = 4

   # Your Slack webhook URL
   slack_webhook_url = "https://hooks.slack.com/services/YOUR/ACTUAL/WEBHOOK/URL"
   ```

## Step 3: Initialize and Deploy

1. **Initialize Terraform:**
   ```powershell
   terraform init
   ```

2. **Plan the deployment:**
   ```powershell
   terraform plan
   ```

3. **Deploy the infrastructure:**
   ```powershell
   terraform apply
   ```
   - Review the plan and type `yes` when prompted
   - Deployment takes approximately 15-20 minutes

## Step 4: Verify Deployment

### Check Core Infrastructure
```powershell
# List created resources
az resource list --resource-group rg-autopot --output table

# Verify Key Vault
az keyvault list --resource-group rg-autopot

# Check honey users
az ad user list --query "[?contains(userPrincipalName, 'autopot')]"
```

### Verify Monitoring Components
```powershell
# Check Log Analytics workspace
az monitor log-analytics workspace list --resource-group rg-autopot

# Verify Sentinel onboarding
az sentinel workspace list --resource-group rg-autopot

# Check Function App
az functionapp list --resource-group rg-autopot
```

## Step 5: Test Monitoring

### Test Slack Notifications
1. Navigate to your Function App in Azure Portal
2. Go to Functions → `slack_notifier`
3. Click "Test/Run" and send a test payload:
   ```json
   {
     "title": "Test AutoPot Alert",
     "severity": "High",
     "description": "This is a test notification from AutoPot monitoring"
   }
   ```

### Trigger Security Events
1. **Test honey user login:**
   - Try signing in with a honey user account
   - Check Slack for alerts within 5 minutes

2. **Test SQL access:**
   - Connect to the SQL server using SQL Server Management Studio
   - Use the intentionally weak credentials
   - Monitor for database access alerts

3. **Test Key Vault access:**
   - Access Key Vault secrets through Azure Portal
   - Watch for credential access notifications

## Monitoring Dashboard

### Access Sentinel
1. Go to Azure Portal → Microsoft Sentinel
2. Select your Log Analytics workspace
3. Navigate to:
   - **Incidents**: View detected security events
   - **Analytics**: See configured detection rules
   - **Workbooks**: Monitor honeypot activity

### Key Metrics to Monitor
- **Honey User Sign-ins**: Any authentication attempts
- **SQL Server Access**: Database connection attempts
- **Key Vault Operations**: Secret access patterns
- **Web Portal Traffic**: Suspicious web activity
- **Privilege Escalation**: Role assignment changes

## Troubleshooting

### Common Issues

1. **Terraform Deployment Fails:**
   ```powershell
   # Check provider versions
   terraform version
   
   # Validate configuration
   terraform validate
   
   # Re-initialize if needed
   terraform init -upgrade
   ```

2. **Function App Not Deploying:**
   - Check if storage account name is unique
   - Verify Function App name doesn't conflict
   - Ensure sufficient Azure quotas

3. **Slack Notifications Not Working:**
   - Verify webhook URL is correct
   - Check Function App logs in Application Insights
   - Test webhook manually with curl:
     ```powershell
     curl -X POST -H 'Content-type: application/json' --data '{"text":"Test message"}' YOUR_WEBHOOK_URL
     ```

4. **Sentinel Rules Not Firing:**
   - Confirm data ingestion in Log Analytics
   - Check rule queries in Logs section
   - Verify diagnostic settings are enabled

### Log Locations
- **Function App Logs**: Application Insights → Logs
- **Sentinel Incidents**: Microsoft Sentinel → Incidents
- **Resource Diagnostics**: Log Analytics → Logs
- **Terraform State**: Azure Storage Account (backend)

## Security Considerations

### Access Control
- Function Apps use managed identities
- Minimum required permissions assigned
- Slack webhook URL stored securely
- Key Vault access properly restricted

### Data Retention
- Log Analytics: 90 days retention
- Application Insights: Default retention
- Diagnostic logs: Encrypted at rest
- Incident history: Retained in Sentinel

### Cost Management
- Function Apps: Consumption plan (pay-per-execution)
- Log Analytics: Pay-as-you-go pricing
- Storage: Standard LRS for cost efficiency
- Monitor costs in Azure Cost Management

## Maintenance

### Regular Tasks
1. **Weekly**: Review Sentinel incidents and false positives
2. **Monthly**: Update Function App dependencies
3. **Quarterly**: Review and tune detection rules
4. **Annually**: Rotate honey user passwords

### Updates
```powershell
# Update Terraform modules
terraform init -upgrade

# Apply configuration changes
terraform plan
terraform apply
```

## Support

### Getting Help
1. Check Function App logs for errors
2. Review Sentinel incident details
3. Validate Log Analytics data ingestion
4. Test components individually

### Useful Commands
```powershell
# Check resource status
az resource list --resource-group rg-autopot --query "[].{Name:name,Type:type,Status:properties.provisioningState}"

# View recent logs
az monitor activity-log list --resource-group rg-autopot --max-events 10

# Test Function App
az functionapp function invoke --name YOUR_FUNCTION_APP --function-name slack_notifier --data '{"test":"message"}'
```

## Next Steps

After successful deployment:
1. Configure additional Slack channels for different alert types
2. Customize detection rules based on your environment
3. Set up automated incident response playbooks
4. Integrate with existing SIEM/SOAR tools
5. Create custom dashboards for executive reporting

The AutoPot monitoring system is now ready to detect and alert on suspicious activities across your honeypot infrastructure!
