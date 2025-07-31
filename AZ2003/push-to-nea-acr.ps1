# PowerShell script to push Docker image to NEA.AD Azure Container Registry

# Parameters - Update these with your NEA.AD registry values
$RegistryName = "acraz2003ou17juli"  # Your NEA.AD ACR name (replace with actual name)
$ImageName = "aspnetcorecontainer"
$ImageTag = "latest"
$SubscriptionId = "9e89f2d0-f39d-4ade-aa60-23ee14a02deb"  # NEA - Microsoft Azure subscription

# NEA.AD Admin Credentials
$username = "acraz2003ou17juli"
$password = "YOUR_NEA_ADMIN_PASSWORD_HERE"  # Replace with actual password

# Azure Container Registry login endpoint
$LoginServer = "$RegistryName.azurecr.io"

Write-Host "Starting Docker push process to NEA.AD Azure Container Registry..." -ForegroundColor Green

# Step 1: Login to Azure Container Registry using admin credentials
Write-Host "Logging into NEA.AD Azure Container Registry: $LoginServer" -ForegroundColor Yellow
try {
    echo $password | docker login $LoginServer --username $username --password-stdin
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to login to NEA.AD Azure Container Registry"
    }
    Write-Host "Successfully logged into NEA.AD Azure Container Registry" -ForegroundColor Green
}
catch {
    Write-Host "Error logging into NEA.AD ACR: $_" -ForegroundColor Red
    Write-Host "Please verify the registry name and credentials are correct." -ForegroundColor Yellow
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
