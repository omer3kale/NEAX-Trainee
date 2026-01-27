# PowerShell script to push Docker image to Azure Container Registry
# Enhanced with robust authentication, error handling, and secure credential management

# Load configuration from JSON file
$ConfigPath = Join-Path $PSScriptRoot "..\config\azure-deployments.json"
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
    $RegistryConfig1 = $Config.registries.dev
    $RegistryConfig2 = $Config.registries.nea
    $RegistryName1 = $RegistryConfig1.name
    $RegistryName2 = $RegistryConfig2.name
    $SubscriptionId = $RegistryConfig1.subscriptionId
} else {
    # Fallback to hardcoded values if config file doesn't exist
    $RegistryName1 = "acraz2003cah25oct"  # Your ACR name for DEV.AF
    $RegistryName2 = "acraz2003ou17juli"  # Your ACR name for NEUMAN & ESSER
    $SubscriptionId = "9b7860bb-19cc-428f-ad31-3e38fd5d4d9c"  # DEV.AF subscription
}

$ImageName = "aspnetcorecontainer"
$ImageTag = "latest"

# Azure Container Registry login endpoints
$LoginServer1 = "$RegistryName1.azurecr.io"
$LoginServer2 = "$RegistryName2.azurecr.io"

Write-Host "Starting Docker push process to Azure Container Registries..." -ForegroundColor Green

# Pre-flight checks
Write-Host "Performing pre-flight checks..." -ForegroundColor Yellow

# Check if Docker is running
try {
    docker version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running or not installed"
    }
    Write-Host "✓ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Docker check failed: $_" -ForegroundColor Red
    Write-Host "Please ensure Docker Desktop is installed and running" -ForegroundColor Red
    exit 1
}

# Check if Azure CLI is installed
try {
    az version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI is not installed"
    }
    Write-Host "✓ Azure CLI is installed" -ForegroundColor Green
}
catch {
    Write-Host "✗ Azure CLI check failed: $_" -ForegroundColor Red
    Write-Host "Please install Azure CLI from https://aka.ms/install-azure-cli" -ForegroundColor Red
    exit 1
}

# Check if the local image exists
try {
    docker image inspect "$ImageName`:$ImageTag" > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Local image not found"
    }
    Write-Host "✓ Local image '$ImageName`:$ImageTag' exists" -ForegroundColor Green
}
catch {
    Write-Host "✗ Local image check failed: $_" -ForegroundColor Red
    Write-Host "Please build the Docker image first using: docker build -t $ImageName`:$ImageTag ." -ForegroundColor Red
    exit 1
}

# Check Azure authentication status
Write-Host "Checking Azure authentication status..." -ForegroundColor Yellow
try {
    $currentAccount = az account show --query "user.name" --output tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠ Azure CLI authentication required" -ForegroundColor Yellow
        Write-Host "Please run 'az login' to authenticate" -ForegroundColor Yellow
        az login
        if ($LASTEXITCODE -ne 0) {
            throw "Azure authentication failed"
        }
    }
    Write-Host "✓ Azure CLI authenticated as: $currentAccount" -ForegroundColor Green
}
catch {
    Write-Host "✗ Azure authentication check failed: $_" -ForegroundColor Red
    Write-Host "Error Code 53003 indicates Azure AD authentication issues" -ForegroundColor Red
    Write-Host "Try running 'az login --scope https://management.core.windows.net//.default'" -ForegroundColor Red
    exit 1
}

# Function to login and push to a registry
function Push-ToRegistry {
    param (
        [string]$RegistryName,
        [string]$LoginServer,
        [string]$ImageName,
        [string]$ImageTag,
        [string]$SubscriptionId,
        [string]$RegistryType  # "dev" or "nea"
    )

    # Step 1: Login to Azure Container Registry with enhanced error handling
    Write-Host "Logging into Azure Container Registry: $LoginServer" -ForegroundColor Yellow
    
    # Determine environment variable names based on registry type
    $usernameEnvVar = if ($RegistryType -eq "dev") { "AZURE_ACR_USERNAME_DEV" } else { "AZURE_ACR_USERNAME_NEA" }
    $passwordEnvVar = if ($RegistryType -eq "dev") { "AZURE_ACR_PASSWORD_DEV" } else { "AZURE_ACR_PASSWORD_NEA" }
    $keyVaultSecretName = if ($RegistryType -eq "dev") { "acr-dev-password" } else { "acr-nea-password" }
    
    # Try to get credentials from environment or Key Vault
    $username = [Environment]::GetEnvironmentVariable($usernameEnvVar)
    $password = [Environment]::GetEnvironmentVariable($passwordEnvVar)
    $KeyVaultName = $env:AZURE_KEY_VAULT_NAME
    
    # Try Azure Key Vault first if configured
    if ($KeyVaultName -and -not $password) {
        Write-Host "Attempting to retrieve credentials from Azure Key Vault..." -ForegroundColor Yellow
        try {
            $password = az keyvault secret show --name $keyVaultSecretName --vault-name $KeyVaultName --query value -o tsv 2>$null
            if ($LASTEXITCODE -eq 0 -and $password) {
                $username = $RegistryName
                Write-Host "✓ Credentials retrieved from Key Vault" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "⚠ Could not retrieve from Key Vault, trying other methods..." -ForegroundColor Yellow
        }
    }
    
    # Method 1: Try credentials if available
    $authSuccess = $false
    
    if ($username -and $password) {
        Write-Host "Using provided credentials for $RegistryType registry..." -ForegroundColor Yellow
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
    
    # Method 2: Try Azure CLI token-based authentication
    if (-not $authSuccess) {
        Write-Host "Trying Azure CLI token-based authentication..." -ForegroundColor Yellow
        $maxRetries = 3
    
        for ($i = 1; $i -le $maxRetries; $i++) {
            try {
                Write-Host "Attempt $i/$maxRetries - Getting Azure CLI refresh token..." -ForegroundColor Yellow
            
            # Clear any existing authentication issues
            az account clear 2>$null
            
            # Re-authenticate to Azure CLI
            Write-Host "Re-authenticating to Azure CLI..." -ForegroundColor Yellow
            $loginResult = az login --scope https://management.core.windows.net//.default --query "[]" --output json 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "Azure CLI login failed"
            }
            
            # Set the subscription
            az account set --subscription $SubscriptionId
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to set subscription"
            }
            
            # Get refresh token from Azure
            $refreshToken = az acr login -n $RegistryName --expose-token --subscription $SubscriptionId --query accessToken --output tsv
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to get refresh token"
            }
            
            # Use the refresh token to login to Docker
            Write-Host "Using refresh token to login to Docker..." -ForegroundColor Yellow
            echo $refreshToken | docker login $LoginServer --username 00000000-0000-0000-0000-000000000000 --password-stdin
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to login to Docker with refresh token"
            }
                
                $authSuccess = $true
                Write-Host "Successfully logged into Azure Container Registry using Azure CLI token" -ForegroundColor Green
                break
            }
            catch {
                Write-Host "Attempt $i failed: $_" -ForegroundColor Red
                if ($i -eq $maxRetries) {
                    Write-Host "All Azure CLI token attempts failed. Trying direct ACR login..." -ForegroundColor Yellow
                } else {
                    Write-Host "Waiting 5 seconds before retry..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 5
                }
            }
        }
    }
    
    # Method 3: Try direct ACR login as final fallback
    if (-not $authSuccess) {
        Write-Host "Trying direct ACR login..." -ForegroundColor Yellow
        try {
            az acr login --name $RegistryName --subscription $SubscriptionId
            if ($LASTEXITCODE -eq 0) {
                $authSuccess = $true
                Write-Host "✓ Successfully logged in using direct ACR login" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "✗ Direct ACR login failed: $_" -ForegroundColor Red
        }
    }
    
    # Final check - if all methods failed
    if (-not $authSuccess) {
        Write-Host ""
        Write-Host "✗ All authentication methods failed for $RegistryType registry!" -ForegroundColor Red
        Write-Host ""
        Write-Host "To fix this, choose one of these methods:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1 - Use Environment Variables:" -ForegroundColor Cyan
        Write-Host "  `$env:$usernameEnvVar = `"$RegistryName`"" -ForegroundColor White
        Write-Host "  `$env:$passwordEnvVar = `"your_password`"" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2 - Use Azure Key Vault:" -ForegroundColor Cyan
        Write-Host '  $env:AZURE_KEY_VAULT_NAME = "your-keyvault-name"' -ForegroundColor White
        Write-Host "  az keyvault secret set --vault-name `"your-keyvault-name`" --name `"$keyVaultSecretName`" --value `"your_password`"" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 3 - Use Azure CLI:" -ForegroundColor Cyan
        Write-Host "  az login" -ForegroundColor White
        Write-Host ""
        exit 1
    }

    # Step 2: Tag the image with the registry name
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

    # Step 3: Push the image to Azure Container Registry
    Write-Host "Pushing image to Azure Container Registry: $RemoteImageTag" -ForegroundColor Yellow
    try {
        docker push $RemoteImageTag
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to push image"
        }
        Write-Host "Successfully pushed image to Azure Container Registry!" -ForegroundColor Green
        Write-Host "Image URL: $RemoteImageTag" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error pushing image: $_" -ForegroundColor Red
        exit 1
    }

    # Step 4: Verify the push
    Write-Host "Verifying the pushed image..." -ForegroundColor Yellow
    try {
        az acr repository show --name $RegistryName --repository $ImageName
        Write-Host "Image verification successful!" -ForegroundColor Green
    }
    catch {
        Write-Host "Note: Image was pushed but verification failed. This might be due to permissions." -ForegroundColor Yellow
    }
}

# Push to first registry (DEV)
Push-ToRegistry -RegistryName $RegistryName1 -LoginServer $LoginServer1 -ImageName $ImageName -ImageTag $ImageTag -SubscriptionId $SubscriptionId -RegistryType "dev"

# Push to second registry (NEA)
Push-ToRegistry -RegistryName $RegistryName2 -LoginServer $LoginServer2 -ImageName $ImageName -ImageTag $ImageTag -SubscriptionId $SubscriptionId -RegistryType "nea"

# Display the final status
Write-Host "`nDocker push process completed successfully to both registries!" -ForegroundColor Green
Write-Host "`n=== Multi-Registry Deployment Summary ===" -ForegroundColor Cyan
Write-Host "Local Image: ${ImageName}:${ImageTag}" -ForegroundColor Yellow
Write-Host "`nRegistry 1: $RegistryName1.azurecr.io" -ForegroundColor Cyan
Write-Host "  Tenant: DEV.AF" -ForegroundColor White
Write-Host "  Image: ${ImageName}:${ImageTag}" -ForegroundColor White
Write-Host "  Status: Successfully Pushed" -ForegroundColor Green
Write-Host "`nRegistry 2: $RegistryName2.azurecr.io" -ForegroundColor Cyan
Write-Host "  Tenant: NEUMAN & ESSER" -ForegroundColor White
Write-Host "  Image: ${ImageName}:${ImageTag}" -ForegroundColor White
Write-Host "  Status: Successfully Pushed" -ForegroundColor Green
Write-Host "`n=========================================" -ForegroundColor Cyan
