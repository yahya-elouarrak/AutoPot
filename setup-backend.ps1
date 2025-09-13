#!/usr/bin/env pwsh
# Script to setup Azure Storage for Terraform Backend

# Variables
$RESOURCE_GROUP_NAME="rg-autopot"  # Same RG as other resources
$STORAGE_ACCOUNT_NAME="stautopot"   # Storage account for project
$CONTAINER_NAME="tfstate"
$LOCATION="francecentral"
$ENVIRONMENT="dev"
$PROJECT="autopot"


# Login to Azure
Write-Host "Logging into Azure..." -ForegroundColor Blue
az login

# Create resource group for all resources
Write-Host "Creating resource group..." -ForegroundColor Blue
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account with enhanced security
Write-Host "Creating storage account..." -ForegroundColor Blue
az storage account create `
    --name $STORAGE_ACCOUNT_NAME `
    --resource-group $RESOURCE_GROUP_NAME `
    --location $LOCATION `
    --sku Standard_LRS `
    --encryption-services blob `
    --min-tls-version TLS1_2 `
    --allow-shared-key-access true `
    --https-only true `

# Get storage account key
$ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create blob container with private access
Write-Host "Creating storage container..." -ForegroundColor Blue
az storage container create `
    --name $CONTAINER_NAME `
    --account-name $STORAGE_ACCOUNT_NAME `
    --account-key $ACCOUNT_KEY

# Create backend config file
# $backendConfig = @"
# resource_group_name  = "$RESOURCE_GROUP_NAME"
# storage_account_name = "$STORAGE_ACCOUNT_NAME"
# container_name       = "$CONTAINER_NAME"
# key                 = "autopot.tfstate"
# "@

# Set-Content -Path "backend.conf" -Value $backendConfig

# Write-Host "Backend storage has been configured. You can now run: terraform init -backend-config=backend.conf" -ForegroundColor Green

# Export environment variables for Terraform
$env:ARM_ACCESS_KEY = $ACCOUNT_KEY
Write-Host "Storage account access key has been set as environment variable ARM_ACCESS_KEY" -ForegroundColor Green
