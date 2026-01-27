# PowerShell script to push Docker image to NEA.AD Azure Container Registry
# Enhanced with secure credential management

# Load configuration from JSON file
$ConfigPath = Join-Path $PSScriptRoot "..\config\azure-deployments.json"
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
    $RegistryConfig = $Config.registries.nea
    $RegistryName = $RegistryConfig.name
    $SubscriptionId = $RegistryConfig.subscriptionId
} else {
    # Fallback to hardcoded values if config file doesn't exist
    $RegistryName = "acraz2003ou17juli"
    $SubscriptionId = "9e89f2d0-f39d-4ade-aa60-23ee14a02deb"
}

# Image configuration
$ImageName = "aspnetcorecontainer"
$ImageTag = "latest"

# Azure Container Registry login endpoint
$LoginServer = "$RegistryName.azurecr.io"

# Secure credential retrieval
# Priority: 1) Azure Key Vault, 2) Environment Variables, 3) Azure CLI
$username = $env:AZURE_ACR_USERNAME_NEA
$password = $env:AZURE_ACR_PASSWORD_NEA
$KeyVaultName = $env:AZURE_KEY_VAULT_NAME

# Try to get password from Azure Key Vault if configured
if ($KeyVaultName -and -not $password) {
    Write-Host "Attempting to retrieve credentials from Azure Key Vault..." -ForegroundColor Yellow
    try {
        $password = az keyvault secret show --name "acr-nea-password" --vault-name $KeyVaultName --query value -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and $password) {
            $username = $RegistryName
            Write-Host "✓ Credentials retrieved from Key Vault" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "⚠ Could not retrieve from Key Vault, trying other methods..." -ForegroundColor Yellow
    }
}

Write-Host "Starting Docker push process to NEA.AD Azure Container Registry..." -ForegroundColor Green

# Step 1: Login to Azure Container Registry
Write-Host "Logging into NEA.AD Azure Container Registry: $LoginServer" -ForegroundColor Yellow

$authSuccess = $false

# Method 1: Use credentials if available (from environment or Key Vault)
if ($username -and $password) {
    Write-Host "Using provided credentials..." -ForegroundColor Yellow
    try {
        echo $password | docker login $LoginServer --username $username --password-stdin
        if ($LASTEXITCODE -eq 0) {
            $authSuccess = $true
            Write-Host "✓ Successfully logged in with credentials" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "⚠ Credential-based login failed: $_" -ForegroundColor Yellow
    }
}

# Method 2: Fallback to Azure CLI authentication
if (-not $authSuccess) {
    Write-Host "⚠ No credentials found. Using Azure CLI authentication..." -ForegroundColor Yellow
    Write-Host "Make sure you're logged in with 'az login'" -ForegroundColor Cyan
    try {
        az acr login --name $RegistryName --subscription $SubscriptionId
        if ($LASTEXITCODE -eq 0) {
            $authSuccess = $true
            Write-Host "✓ Successfully logged in with Azure CLI" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Azure CLI login failed: $_" -ForegroundColor Red
    }
}

if (-not $authSuccess) {
    Write-Host ""
    Write-Host "✗ All authentication methods failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To fix this, choose one of these methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1 - Use Environment Variables:" -ForegroundColor Cyan
    Write-Host '  $env:AZURE_ACR_USERNAME_NEA = "acraz2003ou17juli"' -ForegroundColor White
    Write-Host '  $env:AZURE_ACR_PASSWORD_NEA = "your_password"' -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2 - Use Azure Key Vault:" -ForegroundColor Cyan
    Write-Host '  $env:AZURE_KEY_VAULT_NAME = "your-keyvault-name"' -ForegroundColor White
    Write-Host '  az keyvault secret set --vault-name "your-keyvault-name" --name "acr-nea-password" --value "your_password"' -ForegroundColor White
    Write-Host ""
    Write-Host "Option 3 - Use Azure CLI:" -ForegroundColor Cyan
    Write-Host "  az login" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Step 2: Tag the image with the NEA.AD registry name
$LocalImageTag = "$ImageName`:$ImageTag"
$RemoteImageTag = "$LoginServer/$ImageName`:$ImageTag"

Write-Host "Tagging image: $LocalImageTag -> $RemoteImageTag" -ForegroundColor Yellow
try {
    docker tag $LocalImageTag $RemoteImageTag
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to tag image"
    }
    Write-Host "Successfully tagged image" -ForegroundColor Green
}
catch {
    Write-Host "Error tagging image: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Push the image to NEA.AD Azure Container Registry
Write-Host "Pushing image to NEA.AD Azure Container Registry: $RemoteImageTag" -ForegroundColor Yellow
try {
    docker push $RemoteImageTag
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push image"
    }
    Write-Host "Successfully pushed image to NEA.AD Azure Container Registry!" -ForegroundColor Green
    Write-Host "Image URL: $RemoteImageTag" -ForegroundColor Cyan
}
catch {
    Write-Host "Error pushing image: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Verify the push
Write-Host "Verifying the pushed image..." -ForegroundColor Yellow
try {
    az acr repository show --name $RegistryName --repository $ImageName --subscription $SubscriptionId
    Write-Host "Image verification successful!" -ForegroundColor Green
}
catch {
    Write-Host "Note: Image was pushed but verification failed. This might be due to permissions." -ForegroundColor Yellow
}

Write-Host "Docker push process to NEA.AD completed successfully!" -ForegroundColor Green

# Display summary
Write-Host "`n=== PUSH SUMMARY ===" -ForegroundColor Cyan
Write-Host "Registry: $LoginServer" -ForegroundColor White
Write-Host "Image: $RemoteImageTag" -ForegroundColor White
Write-Host "Tenant: NEUMAN & ESSER (NEA.AD)" -ForegroundColor White
Write-Host "Subscription: NEA - Microsoft Azure" -ForegroundColor White
