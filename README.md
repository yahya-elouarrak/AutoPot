# AutoPot

**Sophisticated Honeypot Infrastructure with Enterprise-Grade Monitoring**

AutoPot is a comprehensive deception-based cybersecurity solution that creates realistic honeypot environments to detect, analyze, and alert on malicious activities. Built with Azure cloud services and automated with Terraform, it provides enterprise-grade threat detection with real-time Slack notifications.

## 🎯 Overview

AutoPot turns the tables on attackers by creating irresistible decoy environments that waste their time while gathering valuable threat intelligence. The system automatically detects and alerts on suspicious activities across multiple attack vectors.

### Key Features

- 🧑‍💼 **Realistic Honey Users**: Azure AD accounts with believable profiles across departments
- 🌐 **Deceptive Web Portal**: Legitimate-looking corporate login interface
- 🗄️ **Vulnerable SQL Database**: Intentionally exposed database with "sensitive" data
- 🔐 **Key Vault Honeypot**: Credential store that attracts attackers
- 🚨 **Microsoft Sentinel Integration**: Enterprise SIEM with custom detection rules
- 📱 **Real-time Slack Notifications**: Instant alerts with rich context
- ⚡ **Automated Response**: Azure Functions and Logic Apps for incident handling

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AUTOPOT ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  │   DECEPTION     │    │   MONITORING    │    │   NOTIFICATION  │
│  │     LAYER       │───▶│     LAYER       │───▶│     LAYER       │
│  │                 │    │                 │    │                 │
│  │ • Honey Users   │    │ • Log Analytics │    │ • Azure Functions│
│  │ • Web Portal    │    │ • Sentinel SIEM │    │ • Logic Apps    │
│  │ • SQL Database  │    │ • 5 Detection   │    │ • Slack Alerts │
│  │ • Key Vault     │    │   Rules         │    │                 │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and authenticated
- Terraform v1.0+ installed
- PowerShell (for SQL database setup)
- Slack workspace with webhook configured


### 1. Clone Repository

```bash
git clone https://github.com/yourusername/autopot.git
cd autopot
```

### 2. Setup the backend for terraform

```bash
./setup-backend.ps1
```

### 3. Configure Variables

Edit (or create if not exists) `terraform.tfvars`:
```hcl
slack_webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan -out='plan.tfplan'
terraform apply 'plan.tfplan'
```

## 📋 Components

### Identity Module (`modules/identity/`)
Creates realistic honey user accounts with:
- Believable names and job titles
- Department assignments (Finance, HR, IT, etc.)
- Complex passwords stored in Key Vault
- Azure AD group memberships

### Applications Module (`modules/applications/`)
Deploys vulnerable applications:
- **Web Portal**: Deceptive corporate login page
- **SQL Server**: Intentionally exposed with weak credentials
- **Database Tables**: employeesSensitive, payroll, invoices
- **Storage Account**: Portal deployment artifacts

### Monitoring Module (`modules/monitoring/`)
Enterprise-grade security monitoring:
- **Log Analytics**: 90-day retention, centralized logging
- **Microsoft Sentinel**: SIEM with 5 custom detection rules
- **Azure Functions**: Python-based notification processing
- **Logic Apps**: Automated incident response workflows



## 🛠️ Development

### Project Structure
```
autopot/
├── main.tf                 # Root module
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── modules/
│   ├── identity/           # Honey user management
│   ├── applications/       # Vulnerable applications
│   └── monitoring/         # Security monitoring

```


## 🔒 Security Considerations

- All services use managed identities
- RBAC with minimum required permissions
- TLS encryption for all communications
- Secrets stored in Azure Key Vault
- 90-day log retention for compliance


## ⚠️ Disclaimer

This project is for educational and defensive cybersecurity purposes only. Users are responsible for compliance with applicable laws and regulations. Do not use this tool for malicious purposes.

---

