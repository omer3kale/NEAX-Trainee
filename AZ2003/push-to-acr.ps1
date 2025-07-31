# PowerShell script to push Docker image to Azure Container Registry
# Enhanced with robust authentication and error handling

# Parameters - Update these with your actual values
$RegistryName1 = "acraz2003cah25oct"  # Your ACR name for DEV.AF
$RegistryName2 = "acraz2003ou17juli"  # Your ACR name for NEUMAN & ESSER
$ImageName = "aspnetcorecontainer"
$ImageTag = "latest"
$SubscriptionId = "9b7860bb-19cc-428f-ad31-3e38fd5d4d9c"  # DEV.AF subscription

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
        [string]$SubscriptionId
    )

    # Step 1: Login to Azure Container Registry with enhanced error handling
    Write-Host "Logging into Azure Container Registry: $LoginServer" -ForegroundColor Yellow
    
    # Method 1: Try Azure CLI token-based authentication with retry logic
    $maxRetries = 3
    $authSuccess = $false
    
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
                Write-Host "All Azure CLI token attempts failed. Trying alternative authentication methods..." -ForegroundColor Yellow
            } else {
                Write-Host "Waiting 5 seconds before retry..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            }
        }
    }
    
    # Method 2: Try with registry-specific admin credentials
    if (-not $authSuccess) {
        Write-Host "Trying admin credentials for registry: $RegistryName" -ForegroundColor Yellow
        
        # Define credentials for different registries
        $adminCredentials = @{
            "acraz2003cah25oct" = @{
                "username" = "acraz2003cah25oct"
                "password" = "YOUR_ADMIN_PASSWORD_FOR_FIRST_REGISTRY"  # Update with actual password
            }
            "acraz2003ou17juli" = @{
                "username" = "acraz2003ou17juli"
                "password" = "YOUR_NEA_ADMIN_PASSWORD_HERE"  # Replace with actual password
            }
        }
        
        if ($adminCredentials.ContainsKey($RegistryName)) {
            $creds = $adminCredentials[$RegistryName]
            try {
                echo $creds.password | docker login $LoginServer --username $creds.username --password-stdin
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to login with admin credentials"
                }
                $authSuccess = $true
                Write-Host "Successfully logged in with admin credentials for $RegistryName" -ForegroundColor Green
            }
            catch {
                Write-Host "Admin credentials failed for $RegistryName : $_" -ForegroundColor Red
            }
        }
    }
    
    # Method 3: Try direct ACR login as fallback
    if (-not $authSuccess) {
        Write-Host "Trying direct ACR login..." -ForegroundColor Yellow
        try {
            az acr login --name $RegistryName --subscription $SubscriptionId
            if ($LASTEXITCODE -ne 0) {
                throw "Direct ACR login failed"
            }
            $authSuccess = $true
            Write-Host "Successfully logged in using direct ACR login" -ForegroundColor Green
        }
        catch {
            Write-Host "Direct ACR login failed: $_" -ForegroundColor Red
        }
    }
    
    # Final check - if all methods failed
    if (-not $authSuccess) {
        Write-Host "All authentication methods failed. Please check:" -ForegroundColor Red
        Write-Host "  1. Azure CLI installation and version" -ForegroundColor Red
        Write-Host "  2. Network connectivity to Azure" -ForegroundColor Red
        Write-Host "  3. Registry permissions and credentials" -ForegroundColor Red
        Write-Host "  4. Tenant and subscription access" -ForegroundColor Red
        Write-Host "  Error Code: 53003 suggests Azure AD authentication issues" -ForegroundColor Red
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

# Push to first registry
Push-ToRegistry -RegistryName $RegistryName1 -LoginServer $LoginServer1 -ImageName $ImageName -ImageTag $ImageTag -SubscriptionId $SubscriptionId

# Push to second registry
Push-ToRegistry -RegistryName $RegistryName2 -LoginServer $LoginServer2 -ImageName $ImageName -ImageTag $ImageTag -SubscriptionId $SubscriptionId

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
