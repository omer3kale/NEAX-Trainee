# Azure Security Guide

## 🔐 Secure Credential Management for Azure Container Registry

This guide provides best practices and implementation details for securely managing Azure Container Registry (ACR) credentials in the NEAX-Trainee project.

---

## Table of Contents

1. [Overview](#overview)
2. [Security Principles](#security-principles)
3. [Authentication Methods](#authentication-methods)
4. [Quick Start Guide](#quick-start-guide)
5. [Azure Key Vault Setup](#azure-key-vault-setup)
6. [Environment Variable Configuration](#environment-variable-configuration)
7. [Script Usage](#script-usage)
8. [Troubleshooting](#troubleshooting)
9. [Security Best Practices](#security-best-practices)

---

## Overview

The NEAX-Trainee project supports multiple Azure Container Registries across different tenants:

- **DEV.AF Tenant**: `acraz2003cah25oct.azurecr.io`
- **NEUMAN and ESSER Tenant**: `acraz2003ou17juli.azurecr.io`

All deployment scripts have been updated to support secure credential management with multiple authentication methods.

---

## Security Principles

### ✅ DO:
- Use Azure Key Vault for production deployments
- Store credentials in environment variables (never in code)
- Use Azure CLI authentication when possible
- Rotate ACR admin passwords regularly
- Enable audit logging for all ACR operations
- Use managed identities for automated deployments

### ❌ DON'T:
- Commit passwords or secrets to version control
- Hardcode credentials in scripts
- Share credentials via email or chat
- Use the same password across multiple registries
- Disable ACR admin access without alternative authentication

---

## Authentication Methods

Scripts attempt authentication in the following priority order:

### 1. Azure Key Vault (Most Secure) ⭐
**Recommended for**: Production deployments, CI/CD pipelines, shared environments

**Pros**:
- Centralized secret management
- Audit logging enabled
- Access control via Azure RBAC
- Automatic secret rotation support

**Cons**:
- Requires Azure subscription and Key Vault setup
- Additional Azure costs (minimal)

### 2. Environment Variables (Recommended) 👍
**Recommended for**: Local development, personal deployments

**Pros**:
- Simple to set up
- No additional Azure resources needed
- Works offline after initial setup

**Cons**:
- Secrets stored on local machine
- Not suitable for shared environments
- Manual management required

### 3. Azure CLI Authentication (Fallback) 🔄
**Recommended for**: Interactive use, troubleshooting

**Pros**:
- No password management needed
- Uses your Azure AD identity
- Easiest to set up

**Cons**:
- Requires interactive login
- Not suitable for automation
- Token expiration requires re-authentication

---

## Quick Start Guide

### Option 1: Environment Variables (Fastest)

#### PowerShell:
```powershell
# Set credentials for DEV.AF registry
$env:AZURE_ACR_USERNAME_DEV = "acraz2003cah25oct"
$env:AZURE_ACR_PASSWORD_DEV = "your_actual_password"

# Set credentials for NEA registry
$env:AZURE_ACR_USERNAME_NEA = "acraz2003ou17juli"
$env:AZURE_ACR_PASSWORD_NEA = "your_actual_password"

# Run deployment script
.\AZ2003\push-to-nea-acr.ps1
```

#### Bash/Linux:
```bash
# Set credentials
export AZURE_ACR_USERNAME_DEV="acraz2003cah25oct"
export AZURE_ACR_PASSWORD_DEV="your_actual_password"
export AZURE_ACR_USERNAME_NEA="acraz2003ou17juli"
export AZURE_ACR_PASSWORD_NEA="your_actual_password"

# Run deployment script
pwsh ./AZ2003/push-to-nea-acr.ps1
```

### Option 2: Use .env.azure File

1. Copy the example file:
```bash
cp .env.azure.example .env.azure
```

2. Edit `.env.azure` with your actual credentials:
```bash
# .env.azure
AZURE_ACR_USERNAME_DEV=acraz2003cah25oct
AZURE_ACR_PASSWORD_DEV=your_actual_password
AZURE_ACR_USERNAME_NEA=acraz2003ou17juli
AZURE_ACR_PASSWORD_NEA=your_actual_password
```

3. Load the environment variables:

**PowerShell**:
```powershell
Get-Content .env.azure | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}
```

**Bash**:
```bash
source .env.azure
```

### Option 3: Azure CLI Authentication (No Passwords)

```bash
# Login to Azure
az login

# Run deployment script (will use Azure CLI auth automatically)
pwsh ./AZ2003/push-to-nea-acr.ps1
```

---

## Azure Key Vault Setup

### Step 1: Create a Key Vault

```bash
# Set variables
RESOURCE_GROUP="rg-neax-trainee"
KEY_VAULT_NAME="neax-trainee-kv"
LOCATION="westeurope"

# Create resource group (if needed)
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Key Vault
az keyvault create \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true
```

### Step 2: Store ACR Passwords

```bash
# Store DEV registry password
az keyvault secret set \
  --vault-name $KEY_VAULT_NAME \
  --name "acr-dev-password" \
  --value "your_dev_password"

# Store NEA registry password
az keyvault secret set \
  --vault-name $KEY_VAULT_NAME \
  --name "acr-nea-password" \
  --value "your_nea_password"
```

### Step 3: Grant Access

```bash
# Grant yourself access
az keyvault set-policy \
  --name $KEY_VAULT_NAME \
  --upn "your@email.com" \
  --secret-permissions get list

# For service principals (CI/CD):
az keyvault set-policy \
  --name $KEY_VAULT_NAME \
  --spn "service-principal-app-id" \
  --secret-permissions get list
```

### Step 4: Configure Scripts to Use Key Vault

```powershell
# Set Key Vault name as environment variable
$env:AZURE_KEY_VAULT_NAME = "neax-trainee-kv"

# Run deployment (will automatically use Key Vault)
.\AZ2003\push-to-nea-acr.ps1
```

---

## Environment Variable Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_ACR_USERNAME_DEV` | DEV.AF registry username | `acraz2003cah25oct` |
| `AZURE_ACR_PASSWORD_DEV` | DEV.AF registry password | `your_password` |
| `AZURE_ACR_USERNAME_NEA` | NEA registry username | `acraz2003ou17juli` |
| `AZURE_ACR_PASSWORD_NEA` | NEA registry password | `your_password` |
| `AZURE_KEY_VAULT_NAME` | Key Vault name (optional) | `neax-trainee-kv` |

### Setting Persistent Environment Variables

#### Windows PowerShell (User-level):
```powershell
[Environment]::SetEnvironmentVariable("AZURE_ACR_USERNAME_DEV", "acraz2003cah25oct", "User")
[Environment]::SetEnvironmentVariable("AZURE_ACR_PASSWORD_DEV", "your_password", "User")
```

#### Windows Command Prompt:
```cmd
setx AZURE_ACR_USERNAME_DEV "acraz2003cah25oct"
setx AZURE_ACR_PASSWORD_DEV "your_password"
```

#### Linux/Mac (Bash - add to ~/.bashrc or ~/.zshrc):
```bash
export AZURE_ACR_USERNAME_DEV="acraz2003cah25oct"
export AZURE_ACR_PASSWORD_DEV="your_password"
```

---

## Script Usage

### Available Scripts

#### 1. `scripts/azure-credential-manager.ps1`
Manages Azure credentials with multiple operations.

```powershell
# Get credentials for DEV registry
.\scripts\azure-credential-manager.ps1 -Action Get -Registry Dev

# Get credentials for NEA registry
.\scripts\azure-credential-manager.ps1 -Action Get -Registry Nea

# Set credentials interactively
.\scripts\azure-credential-manager.ps1 -Action Set -Registry Dev

# List available registries
.\scripts\azure-credential-manager.ps1 -Action List

# Remove stored credentials
.\scripts\azure-credential-manager.ps1 -Action Remove -Registry Dev

# Use Key Vault
.\scripts\azure-credential-manager.ps1 -Action Get -Registry Dev -UseKeyVault -KeyVaultName "neax-trainee-kv"
```

#### 2. `scripts/get-azure-secrets.ps1`
Retrieves secrets from Azure Key Vault.

```powershell
# Get secret and display it
.\scripts\get-azure-secrets.ps1 -KeyVaultName "neax-trainee-kv" -SecretName "acr-dev-password" -AsPlainText

# Get secret and set as environment variable
.\scripts\get-azure-secrets.ps1 -KeyVaultName "neax-trainee-kv" -SecretName "acr-dev-password" -SetEnvironmentVariable -EnvironmentVariableName "AZURE_ACR_PASSWORD_DEV"
```

#### 3. `scripts/encrypt-secrets.ps1`
Encrypts and decrypts secrets using Windows DPAPI.

```powershell
# Encrypt a secret
.\scripts\encrypt-secrets.ps1 -Action Encrypt -PlainText "my_password"

# Decrypt a secret
.\scripts\encrypt-secrets.ps1 -Action Decrypt -PlainText "encrypted_string_here"

# Encrypt from file
.\scripts\encrypt-secrets.ps1 -Action Encrypt -InputFile "secret.txt" -OutputFile "secret.encrypted"

# Decrypt from file
.\scripts\encrypt-secrets.ps1 -Action Decrypt -InputFile "secret.encrypted" -OutputFile "secret.txt"
```

### Deployment Scripts

#### Push to NEA Registry:
```powershell
.\AZ2003\push-to-nea-acr.ps1
```

#### Push to Both Registries:
```powershell
.\AZ2003\push-to-acr.ps1
```

#### View Deployment Summary:
```powershell
.\AZ2003\deployment-summary.ps1
```

---

## Troubleshooting

### Issue: "All authentication methods failed"

**Solution**:
1. Verify Azure CLI is installed: `az --version`
2. Check if you're logged in: `az account show`
3. Login if needed: `az login`
4. Set environment variables or use Key Vault

### Issue: "Failed to retrieve secret from Key Vault"

**Causes**:
- Key Vault doesn't exist
- Secret doesn't exist
- No permissions to access secrets
- Firewall blocking access

**Solutions**:
```bash
# Check if Key Vault exists
az keyvault show --name "neax-trainee-kv"

# List secrets
az keyvault secret list --vault-name "neax-trainee-kv"

# Grant access
az keyvault set-policy --name "neax-trainee-kv" --upn "your@email.com" --secret-permissions get list
```

### Issue: "Docker login failed"

**Solutions**:
1. Verify Docker is running: `docker version`
2. Check credentials are correct
3. Try Azure CLI authentication: `az acr login --name acraz2003ou17juli`
4. Check registry name is correct

### Issue: Environment variables not persisting

**PowerShell**: Set at User or Machine level:
```powershell
[Environment]::SetEnvironmentVariable("VAR_NAME", "value", "User")
```

**Linux/Mac**: Add to shell profile:
```bash
echo 'export VAR_NAME="value"' >> ~/.bashrc
source ~/.bashrc
```

---

## Security Best Practices

### 1. Credential Rotation
Rotate ACR admin passwords every 90 days:
```bash
az acr credential renew --name acraz2003ou17juli --password-name password
```

### 2. Use Service Principals for Automation
Create dedicated service principals for CI/CD:
```bash
az ad sp create-for-rbac --name "neax-trainee-cicd" --role AcrPush --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.ContainerRegistry/registries/{registry-name}
```

### 3. Enable ACR Content Trust
```bash
az acr config content-trust update --name acraz2003ou17juli --status enabled
```

### 4. Enable Vulnerability Scanning
```bash
az acr task create --name scan-on-push --registry acraz2003ou17juli --context /dev/null --cmd "scan" --commit-trigger-enabled true
```

### 5. Network Security
Restrict ACR access by IP:
```bash
az acr network-rule add --name acraz2003ou17juli --ip-address "your.ip.address"
```

### 6. Audit Logging
Enable diagnostic logs:
```bash
az monitor diagnostic-settings create \
  --name acr-audit-logs \
  --resource /subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{registry} \
  --logs '[{"category": "ContainerRegistryRepositoryEvents","enabled": true}]' \
  --workspace {log-analytics-workspace-id}
```

### 7. Least Privilege Access
Use role-based access control (RBAC):
- **AcrPull**: Read-only access (for deployments)
- **AcrPush**: Push and pull access (for CI/CD)
- **AcrDelete**: Full access (for administrators only)

---

## Configuration Files

### `.env.azure.example`
Template for environment variables. Copy to `.env.azure` and fill in your credentials.

### `config/azure-deployments.json`
Central configuration for all Azure resources. Contains non-sensitive data like registry names and subscription IDs.

### `.gitignore`
Ensures credentials are never committed to version control.

---

## Additional Resources

- [Azure Container Registry Documentation](https://docs.microsoft.com/azure/container-registry/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

---

## Support

For issues or questions:
1. Check this guide first
2. Review script output for specific error messages
3. Check Azure portal for ACR and Key Vault status
4. Verify permissions and firewall rules

---

**Last Updated**: January 2026  
**Version**: 1.0.0
