# AutoPot Technical Architecture

## Overview

AutoPot is a comprehensive honeypot infrastructure designed to detect and alert on suspicious activities through deceptive resources and advanced monitoring capabilities.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AUTOPOT ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │   DECEPTION     │    │   MONITORING    │    │   NOTIFICATION  │         │
│  │    LAYER        │───▶│     LAYER       │───▶│     LAYER       │         │
│  │                 │    │                 │    │                 │         │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Deception Layer

#### Identity Module (`modules/identity/`)
**Purpose**: Creates realistic honey user accounts to attract attackers

**Components**:
- **Azure AD Users**: Honey user accounts with realistic profiles
- **User Groups**: Privileged Access Review Group for high-value targets
- **Credential Storage**: Key Vault secrets containing user credentials
- **Random Generation**: Dynamic user profile creation

**Technical Details**:
```hcl
Resource Count: 4-5 honey users (configurable)
Naming Pattern: firstname.lastname@domain.com
Departments: 14 realistic departments (Finance, IT, HR, etc.)
Job Titles: 15 job titles with varying privilege levels
Password Policy: 16 characters, complex requirements
```

#### Applications Module (`modules/applications/`)
**Purpose**: Deploys vulnerable applications as attack targets

**Components**:
- **Web Portal**: Deceptive login interface (App Service)
- **SQL Server**: Intentionally vulnerable database server
- **SQL Database**: Contains sensitive tables (employees, payroll, invoices)
- **Storage Account**: Portal deployment artifacts

**Technical Details**:
```hcl
App Service: Windows, B1 SKU, Node.js runtime
SQL Server: Public access enabled, weak credentials
Database Tables: employeesSensitive, invoices, payroll
Firewall Rules: Intentionally permissive (0.0.0.0-255.255.255.255)
```

### 2. Monitoring Layer

#### Core Monitoring (`modules/monitoring/main.tf`)
**Purpose**: Centralized logging and analysis infrastructure

**Components**:
- **Log Analytics Workspace**: 90-day retention, centralized logging
- **Microsoft Sentinel**: SIEM capabilities, incident management
- **Application Insights**: Function App performance monitoring
- **Diagnostic Settings**: Automatic log collection from all resources

#### Security Detection (`modules/monitoring/sentinel_rules.tf`)
**Purpose**: Automated threat detection and incident creation

**Analytics Rules**:
1. **Honey User Sign-in Detection**
   - Trigger: Any authentication attempt to honey users
   - Severity: Critical (successful) / High (failed)
   - Frequency: Every 5 minutes
   - MITRE: T1078, T1110

2. **SQL Server Suspicious Access**
   - Trigger: Login attempts, database queries, schema access
   - Severity: Critical (successful) / High (failed)
   - Frequency: Every 10 minutes
   - MITRE: T1078, T1082, T1005

3. **Key Vault Access Monitoring**
   - Trigger: Secret operations (Get, List, Set, Delete)
   - Severity: Critical (modification) / High (access)
   - Frequency: Every 15 minutes
   - MITRE: T1555, T1087

4. **Web Portal Activity Detection**
   - Trigger: Multiple requests, admin access, form submissions
   - Severity: High (admin) / Medium (patterns)
   - Frequency: Every 10 minutes
   - MITRE: T1190, T1083

5. **Privilege Escalation Detection**
   - Trigger: Role assignments, permission grants
   - Severity: Critical
   - Frequency: Every 5 minutes
   - MITRE: T1078, T1484

### 3. Notification Layer

#### Azure Functions (`modules/monitoring/function_app/`)
**Purpose**: Automated incident processing and notification delivery

**Functions**:
1. **slack_notifier** (HTTP Triggered)
   - Processes Sentinel incidents
   - Formats rich Slack messages
   - Handles webhook delivery
   - Error handling and logging

2. **security_monitor** (Timer Triggered)
   - Runs every 5 minutes
   - Executes KQL queries
   - Proactive threat hunting
   - Real-time alerting

**Technical Stack**:
```python
Runtime: Python 3.9
Plan: Consumption (Y1)
Dependencies: azure-functions, azure-identity, requests
Authentication: Managed Identity
Storage: Standard LRS
```

#### Logic Apps (`modules/monitoring/logic_apps.tf`)
**Purpose**: Workflow automation for incident response

**Components**:
- **HTTP Trigger**: Receives Sentinel incidents
- **Function Invocation**: Calls slack_notifier function
- **Automation Rules**: Links Sentinel to Logic Apps
- **Error Handling**: Retry logic and failure notifications

## Data Flow Architecture

### 1. Detection Flow
```
Honeypot Resources → Diagnostic Logs → Log Analytics → Sentinel Analytics → Incidents
```

### 2. Notification Flow
```
Sentinel Incident → Automation Rule → Logic App → Function App → Slack
```

### 3. Monitoring Flow
```
Timer Trigger → Function App → KQL Queries → Log Analytics → Threat Detection → Slack
```

## Security Architecture

### Authentication & Authorization
- **Managed Identities**: All services use system-assigned identities
- **RBAC**: Minimum required permissions
- **Key Vault Integration**: Secure credential storage
- **Azure AD Integration**: Centralized identity management

### Network Security
- **Private Endpoints**: Where applicable for secure communication
- **Firewall Rules**: Intentionally permissive for honeypot SQL Server
- **TLS Encryption**: All communications encrypted in transit
- **Storage Encryption**: Data encrypted at rest

### Monitoring Security
- **Log Retention**: 90 days for compliance
- **Access Logging**: All access attempts logged
- **Incident Tracking**: Full audit trail in Sentinel
- **Webhook Security**: Slack webhook URL stored securely

## Deployment Architecture

### Infrastructure as Code
```
providers.tf     → Azure provider configuration
main.tf         → Root module orchestration
variables.tf    → Input parameters
outputs.tf      → Resource references
```

### Module Structure
```
modules/
├── identity/           → Honey user management
│   ├── main.tf        → User and group creation
│   ├── locals.tf      → Name and profile generation
│   ├── random.tf      → Random value generation
│   ├── variables.tf   → Module inputs
│   └── outputs.tf     → User information
├── applications/      → Vulnerable applications
│   ├── main.tf        → App Service and SQL Server
│   ├── locals.tf      → User data formatting
│   ├── variables.tf   → Module inputs
│   └── outputs.tf     → Resource references
└── monitoring/        → Security monitoring
    ├── main.tf        → Core monitoring infrastructure
    ├── sentinel_rules.tf → Detection rules
    ├── logic_apps.tf  → Automation workflows
    ├── variables.tf   → Module inputs
    ├── outputs.tf     → Monitoring references
    └── function_app/  → Notification functions
```

## Scalability Architecture

### Horizontal Scaling
- **Function Apps**: Automatic scaling based on demand
- **Log Analytics**: Scales with data ingestion volume
- **Sentinel**: Handles enterprise-scale security events
- **Storage**: Automatically scales with data growth

### Performance Optimization
- **Query Optimization**: Efficient KQL queries with time windows
- **Caching**: Application Insights caching for Function Apps
- **Resource Sizing**: Right-sized SKUs for cost optimization
- **Parallel Processing**: Multiple detection rules run concurrently

## Cost Architecture

### Resource Pricing Model
```
Log Analytics: Pay-as-you-go ($2.30/GB ingested)
Function Apps: Consumption plan (pay-per-execution)
App Service: B1 Basic ($13.14/month)
SQL Database: Basic tier ($4.99/month)
Storage: Standard LRS ($0.024/GB/month)
Sentinel: $2.00/GB ingested
```

### Cost Optimization Strategies
- **Consumption Plans**: Pay only for actual usage
- **Log Retention**: 90-day retention balances cost and compliance
- **Resource Sizing**: Basic tiers for honeypot resources
- **Query Efficiency**: Optimized detection rules reduce compute costs

## Integration Architecture

### External Integrations
- **Slack**: Real-time notifications via webhooks
- **Azure AD**: Identity provider integration
- **SIEM/SOAR**: Extensible for enterprise security tools
- **Threat Intelligence**: MITRE ATT&CK framework mapping

### API Endpoints
```
Function App: https://{function-app}.azurewebsites.net/api/slack_notifier
Logic App: https://{logic-app}.logic.azure.com/workflows/{workflow-id}/triggers/manual/paths/invoke
Sentinel: REST API for incident management
Log Analytics: KQL query API for custom integrations
```

## Disaster Recovery Architecture

### Backup Strategy
- **Terraform State**: Stored in Azure Storage with versioning
- **Configuration**: Version controlled in Git
- **Logs**: Retained in Log Analytics with geo-redundancy
- **Secrets**: Key Vault with soft delete and purge protection

### Recovery Procedures
1. **Infrastructure Recovery**: `terraform apply` from version control
2. **Data Recovery**: Log Analytics workspace restoration
3. **Configuration Recovery**: Git repository restoration
4. **Monitoring Recovery**: Sentinel rule re-deployment

This architecture provides comprehensive honeypot capabilities with enterprise-grade monitoring, automated threat detection, and real-time notifications while maintaining cost efficiency and scalability.
