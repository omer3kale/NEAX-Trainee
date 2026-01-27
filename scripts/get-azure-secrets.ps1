# Azure Key Vault Secret Retrieval Script
# Securely retrieves secrets from Azure Key Vault

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretName,
    
    [Parameter(Mandatory=$false)]
    [switch]$AsPlainText,
    
    [Parameter(Mandatory=$false)]
    [switch]$SetEnvironmentVariable,
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentVariableName
)

function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Error { param([string]$Message) Write-Host "✗ $Message" -ForegroundColor Red }

Write-Info "Retrieving secret '$SecretName' from Azure Key Vault '$KeyVaultName'..."

# Check if Azure CLI is installed
try {
    az version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Azure CLI is not installed"
        Write-Host "Install from: https://aka.ms/install-azure-cli" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "Azure CLI check failed: $_"
    exit 1
}

# Check Azure authentication
try {
    $currentAccount = az account show --query "user.name" --output tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not authenticated to Azure. Please run 'az login'"
        exit 1
    }
    Write-Info "Authenticated as: $currentAccount"
}
catch {
    Write-Error "Azure authentication check failed: $_"
    exit 1
}

# Retrieve the secret
try {
    Write-Info "Fetching secret..."
    $secret = az keyvault secret show --name $SecretName --vault-name $KeyVaultName --query value -o tsv 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to retrieve secret from Key Vault"
        Write-Host ""
        Write-Host "Possible issues:" -ForegroundColor Yellow
        Write-Host "  • Key Vault does not exist or is in a different subscription" -ForegroundColor White
        Write-Host "  • Secret does not exist in the Key Vault" -ForegroundColor White
        Write-Host "  • You do not have 'Get' permission on the secret" -ForegroundColor White
        Write-Host "  • Key Vault firewall is blocking your IP address" -ForegroundColor White
        Write-Host ""
        Write-Host "To grant access, run:" -ForegroundColor Yellow
        Write-Host "  az keyvault set-policy --name $KeyVaultName --upn <your@email.com> --secret-permissions get list" -ForegroundColor Cyan
        Write-Host ""
        exit 1
    }
    
    if (-not $secret) {
        Write-Error "Secret retrieved but is empty"
        exit 1
    }
    
    Write-Success "Secret retrieved successfully"
    
    # Set as environment variable if requested
    if ($SetEnvironmentVariable) {
        if (-not $EnvironmentVariableName) {
            $EnvironmentVariableName = $SecretName.ToUpper().Replace("-", "_")
        }
        
        [Environment]::SetEnvironmentVariable($EnvironmentVariableName, $secret, "Process")
        Write-Success "Secret set as environment variable: $EnvironmentVariableName"
    }
    
    # Return the secret
    if ($AsPlainText) {
        Write-Host ""
        Write-Host "Secret Value:" -ForegroundColor Yellow
        Write-Host $secret -ForegroundColor Cyan
        Write-Host ""
    }
    
    return $secret
}
catch {
    Write-Error "Failed to retrieve secret: $_"
    exit 1
}
