# Azure Authentication Troubleshooting Script
# Use this script to diagnose and fix Azure authentication issues

Write-Host "Azure Authentication Troubleshooting Script" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Function to check and display Azure CLI version
function Check-AzureCLIVersion {
    Write-Host "`n1. Checking Azure CLI version..." -ForegroundColor Yellow
    try {
        $azVersion = az version --output json | ConvertFrom-Json
        Write-Host "✓ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
        Write-Host "✓ Core version: $($azVersion.'azure-cli-core')" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Azure CLI version check failed: $_" -ForegroundColor Red
        return $false
    }
    return $true
}

# Function to check current authentication status
function Check-AuthStatus {
    Write-Host "`n2. Checking current authentication status..." -ForegroundColor Yellow
    try {
        $account = az account show --output json | ConvertFrom-Json
        Write-Host "✓ Authenticated as: $($account.user.name)" -ForegroundColor Green
        Write-Host "✓ Current tenant: $($account.tenantId)" -ForegroundColor Green
        Write-Host "✓ Current subscription: $($account.name) ($($account.id))" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Not authenticated to Azure CLI" -ForegroundColor Red
        return $false
    }
}

# Function to list available tenants
function List-Tenants {
    Write-Host "`n3. Listing available tenants..." -ForegroundColor Yellow
    try {
        $tenants = az account tenant list --output json | ConvertFrom-Json
        Write-Host "✓ Available tenants:" -ForegroundColor Green
        foreach ($tenant in $tenants) {
            Write-Host "  - $($tenant.displayName) ($($tenant.tenantId))" -ForegroundColor Cyan
        }
        return $true
    }
    catch {
        Write-Host "✗ Failed to list tenants: $_" -ForegroundColor Red
        return $false
    }
}

# Function to fix authentication issues
function Fix-Authentication {
    Write-Host "`n4. Attempting to fix authentication issues..." -ForegroundColor Yellow
    
    # Clear existing authentication
    Write-Host "Clearing existing authentication..." -ForegroundColor Yellow
    az account clear
    
    # Try different authentication methods
    Write-Host "Attempting device code authentication..." -ForegroundColor Yellow
    try {
        # Method 1: Device code authentication
        az login --use-device-code --scope https://management.core.windows.net//.default
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Device code authentication successful" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Device code authentication failed: $_" -ForegroundColor Red
    }
    
    Write-Host "Attempting interactive authentication..." -ForegroundColor Yellow
    try {
        # Method 2: Interactive authentication
        az login --scope https://management.core.windows.net//.default
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Interactive authentication successful" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Interactive authentication failed: $_" -ForegroundColor Red
    }
    
    return $false
}

# Function to test ACR access
function Test-ACRAccess {
    param (
        [string]$RegistryName,
        [string]$SubscriptionId
    )
    
    Write-Host "`n5. Testing ACR access for $RegistryName..." -ForegroundColor Yellow
    
    # Set subscription
    try {
        az account set --subscription $SubscriptionId
        Write-Host "✓ Subscription set to: $SubscriptionId" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to set subscription: $_" -ForegroundColor Red
        return $false
    }
    
    # Test ACR access
    try {
        az acr show --name $RegistryName --output json > $null
        Write-Host "✓ ACR access successful for $RegistryName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ ACR access failed for $RegistryName : $_" -ForegroundColor Red
        return $false
    }
}

# Function to provide recommendations
function Provide-Recommendations {
    Write-Host "`n6. Recommendations for Error Code 53003:" -ForegroundColor Yellow
    Write-Host "  • Error 53003 indicates Azure AD authentication token validation failure" -ForegroundColor Cyan
    Write-Host "  • This often happens when:" -ForegroundColor Cyan
    Write-Host "    - Token has expired" -ForegroundColor White
    Write-Host "    - Network connectivity issues" -ForegroundColor White
    Write-Host "    - Conditional access policies blocking access" -ForegroundColor White
    Write-Host "    - Device compliance issues" -ForegroundColor White
    Write-Host "    - Multi-factor authentication requirements" -ForegroundColor White
    Write-Host "`n  Solutions to try:" -ForegroundColor Cyan
    Write-Host "    1. Re-authenticate with: az login --use-device-code" -ForegroundColor White
    Write-Host "    2. Clear token cache: az account clear" -ForegroundColor White
    Write-Host "    3. Use specific scope: az login --scope https://management.core.windows.net//.default" -ForegroundColor White
    Write-Host "    4. Check network connectivity to Azure endpoints" -ForegroundColor White
    Write-Host "    5. Verify device compliance in Azure AD" -ForegroundColor White
    Write-Host "    6. Contact IT admin if conditional access is blocking" -ForegroundColor White
}

# Main execution
Write-Host "Starting Azure authentication diagnostics..." -ForegroundColor Green

$cliOk = Check-AzureCLIVersion
$authOk = Check-AuthStatus
$tenantsOk = List-Tenants

if (-not $authOk) {
    Write-Host "`nAuthentication issue detected. Attempting to fix..." -ForegroundColor Yellow
    $fixOk = Fix-Authentication
    
    if ($fixOk) {
        $authOk = Check-AuthStatus
        $tenantsOk = List-Tenants
    }
}

if ($authOk) {
    # Test ACR access for both registries
    $acr1Ok = Test-ACRAccess -RegistryName "acraz2003cah25oct" -SubscriptionId "9b7860bb-19cc-428f-ad31-3e38fd5d4d9c"
    $acr2Ok = Test-ACRAccess -RegistryName "acraz2003ou17juli" -SubscriptionId "9e89f2d0-f39d-4ade-aa60-23ee14a02deb"
}

Provide-Recommendations

# Summary
Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "Diagnostics Summary:" -ForegroundColor Green
Write-Host "  Azure CLI: $(if ($cliOk) { '✓' } else { '✗' })" -ForegroundColor $(if ($cliOk) { 'Green' } else { 'Red' })
Write-Host "  Authentication: $(if ($authOk) { '✓' } else { '✗' })" -ForegroundColor $(if ($authOk) { 'Green' } else { 'Red' })
Write-Host "  Tenant Access: $(if ($tenantsOk) { '✓' } else { '✗' })" -ForegroundColor $(if ($tenantsOk) { 'Green' } else { 'Red' })
if ($authOk) {
    Write-Host "  ACR1 Access: $(if ($acr1Ok) { '✓' } else { '✗' })" -ForegroundColor $(if ($acr1Ok) { 'Green' } else { 'Red' })
    Write-Host "  ACR2 Access: $(if ($acr2Ok) { '✓' } else { '✗' })" -ForegroundColor $(if ($acr2Ok) { 'Green' } else { 'Red' })
}
Write-Host "=========================================" -ForegroundColor Green

if ($authOk) {
    Write-Host "`nAuthentication is working! You can now run the push-to-acr.ps1 script." -ForegroundColor Green
} else {
    Write-Host "`nAuthentication issues persist. Please follow the recommendations above." -ForegroundColor Red
}
