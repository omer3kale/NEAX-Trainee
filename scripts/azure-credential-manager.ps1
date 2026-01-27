# Azure Credential Manager
# Secure credential management for Azure Container Registry deployments

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Get", "Set", "List", "Remove")]
    [string]$Action = "Get",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Dev", "Nea")]
    [string]$Registry = "Dev",
    
    [Parameter(Mandatory=$false)]
    [string]$KeyVaultName = $env:AZURE_KEY_VAULT_NAME,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseEnvironmentVariables,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseKeyVault
)

# Color-coded output
function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "✗ $Message" -ForegroundColor Red }

# Registry configurations
$RegistryConfigs = @{
    "Dev" = @{
        "Name" = "acraz2003cah25oct"
        "Server" = "acraz2003cah25oct.azurecr.io"
        "Tenant" = "DEV.AF"
        "SubscriptionId" = "9b7860bb-19cc-428f-ad31-3e38fd5d4d9c"
        "UsernameEnvVar" = "AZURE_ACR_USERNAME_DEV"
        "PasswordEnvVar" = "AZURE_ACR_PASSWORD_DEV"
        "KeyVaultSecretName" = "acr-dev-password"
    }
    "Nea" = @{
        "Name" = "acraz2003ou17juli"
        "Server" = "acraz2003ou17juli.azurecr.io"
        "Tenant" = "NEUMAN and ESSER"
        "SubscriptionId" = "9e89f2d0-f39d-4ade-aa60-23ee14a02deb"
        "UsernameEnvVar" = "AZURE_ACR_USERNAME_NEA"
        "PasswordEnvVar" = "AZURE_ACR_PASSWORD_NEA"
        "KeyVaultSecretName" = "acr-nea-password"
    }
}

# Get credentials from Azure Key Vault
function Get-CredentialsFromKeyVault {
    param([string]$SecretName, [string]$VaultName)
    
    if (-not $VaultName) {
        Write-Warning "No Key Vault name provided. Set AZURE_KEY_VAULT_NAME environment variable."
        return $null
    }
    
    Write-Info "Retrieving secret '$SecretName' from Key Vault '$VaultName'..."
    
    try {
        $secret = az keyvault secret show --name $SecretName --vault-name $VaultName --query value -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and $secret) {
            Write-Success "Secret retrieved from Key Vault"
            return $secret
        }
    }
    catch {
        Write-Warning "Failed to retrieve secret from Key Vault: $_"
    }
    
    return $null
}

# Get credentials from environment variables
function Get-CredentialsFromEnvironment {
    param([string]$UsernameVar, [string]$PasswordVar)
    
    $username = [Environment]::GetEnvironmentVariable($UsernameVar)
    $password = [Environment]::GetEnvironmentVariable($PasswordVar)
    
    if ($username -and $password) {
        Write-Success "Credentials found in environment variables"
        return @{
            "Username" = $username
            "Password" = $password
        }
    }
    
    return $null
}

# Main credential retrieval function
function Get-AzureCredentials {
    param([string]$RegistryType)
    
    $config = $RegistryConfigs[$RegistryType]
    
    if (-not $config) {
        Write-Error "Invalid registry type: $RegistryType"
        exit 1
    }
    
    Write-Info "Getting credentials for $($config.Tenant) registry..."
    
    # Priority 1: Azure Key Vault
    if ($UseKeyVault -or $KeyVaultName) {
        $password = Get-CredentialsFromKeyVault -SecretName $config.KeyVaultSecretName -VaultName $KeyVaultName
        if ($password) {
            return @{
                "Username" = $config.Name
                "Password" = $password
                "Method" = "KeyVault"
                "Config" = $config
            }
        }
    }
    
    # Priority 2: Environment Variables
    $envCreds = Get-CredentialsFromEnvironment -UsernameVar $config.UsernameEnvVar -PasswordVar $config.PasswordEnvVar
    if ($envCreds) {
        return @{
            "Username" = $envCreds.Username
            "Password" = $envCreds.Password
            "Method" = "Environment"
            "Config" = $config
        }
    }
    
    # Priority 3: Azure CLI Authentication (no password needed)
    Write-Warning "No credentials found. Will use Azure CLI authentication."
    return @{
        "Username" = $null
        "Password" = $null
        "Method" = "AzureCLI"
        "Config" = $config
    }
}

# Set credentials in environment
function Set-AzureCredentials {
    param([string]$RegistryType)
    
    $config = $RegistryConfigs[$RegistryType]
    
    Write-Info "Setting credentials for $($config.Tenant) registry..."
    
    $username = Read-Host "Enter ACR username (default: $($config.Name))"
    if (-not $username) { $username = $config.Name }
    
    $password = Read-Host "Enter ACR password" -AsSecureString
    $passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )
    
    # Set environment variables
    [Environment]::SetEnvironmentVariable($config.UsernameEnvVar, $username, "User")
    [Environment]::SetEnvironmentVariable($config.PasswordEnvVar, $passwordPlain, "User")
    
    Write-Success "Credentials saved to user environment variables"
    Write-Warning "Restart PowerShell to use the new credentials"
}

# List available registries
function List-Registries {
    Write-Info "Available Azure Container Registries:"
    Write-Host ""
    
    foreach ($key in $RegistryConfigs.Keys) {
        $config = $RegistryConfigs[$key]
        Write-Host "Registry: $key" -ForegroundColor Yellow
        Write-Host "  Name: $($config.Name)" -ForegroundColor White
        Write-Host "  Server: $($config.Server)" -ForegroundColor White
        Write-Host "  Tenant: $($config.Tenant)" -ForegroundColor White
        Write-Host "  Subscription: $($config.SubscriptionId)" -ForegroundColor White
        Write-Host ""
    }
}

# Remove credentials
function Remove-AzureCredentials {
    param([string]$RegistryType)
    
    $config = $RegistryConfigs[$RegistryType]
    
    Write-Info "Removing credentials for $($config.Tenant) registry..."
    
    [Environment]::SetEnvironmentVariable($config.UsernameEnvVar, $null, "User")
    [Environment]::SetEnvironmentVariable($config.PasswordEnvVar, $null, "User")
    
    Write-Success "Credentials removed from user environment variables"
}

# Execute action
switch ($Action) {
    "Get" {
        $creds = Get-AzureCredentials -RegistryType $Registry
        Write-Host ""
        Write-Host "=== Credential Information ===" -ForegroundColor Cyan
        Write-Host "Registry: $($creds.Config.Name)" -ForegroundColor White
        Write-Host "Server: $($creds.Config.Server)" -ForegroundColor White
        Write-Host "Method: $($creds.Method)" -ForegroundColor White
        Write-Host "Username Available: $($creds.Username -ne $null)" -ForegroundColor White
        Write-Host "Password Available: $($creds.Password -ne $null)" -ForegroundColor White
        return $creds
    }
    "Set" {
        Set-AzureCredentials -RegistryType $Registry
    }
    "List" {
        List-Registries
    }
    "Remove" {
        Remove-AzureCredentials -RegistryType $Registry
    }
}
