# Automated CI/CD Pipeline Script for Docker Deployment
# This script automates the build, test, and deployment process locally

param(
    [string]$Environment = "dev",
    [switch]$SkipTests = $false,
    [switch]$SkipBuild = $false,
    [switch]$Force = $false
)

Write-Host "=== NEA X GmbH Docker CI/CD Pipeline ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Skip Tests: $SkipTests" -ForegroundColor Cyan
Write-Host "Skip Build: $SkipBuild" -ForegroundColor Cyan
Write-Host "Force Deploy: $Force" -ForegroundColor Cyan

# Configuration
$ImageName = "aspnetcorecontainer"
$ImageTag = if ($Environment -eq "prod") { "latest" } else { $Environment }
$RegistryName1 = "acraz2003cah25oct"
$RegistryName2 = "acraz2003ou17juli"

# Step 1: Pre-deployment checks
Write-Host "`n🔍 Step 1: Pre-deployment checks..." -ForegroundColor Yellow

# Check if Docker is running
try {
    docker version > $null 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker not running" }
    Write-Host "✅ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker check failed: $_" -ForegroundColor Red
    exit 1
}

# Check Azure CLI authentication
try {
    $currentUser = az account show --query "user.name" -o tsv 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Not authenticated" }
    Write-Host "✅ Azure CLI authenticated as: $currentUser" -ForegroundColor Green
}
catch {
    Write-Host "❌ Azure authentication required. Run 'az login'" -ForegroundColor Red
    exit 1
}

# Step 2: Run tests (if not skipped)
if (-not $SkipTests) {
    Write-Host "`n🧪 Step 2: Running tests..." -ForegroundColor Yellow
    try {
        dotnet test --configuration Release --logger trx --results-directory ./TestResults
        if ($LASTEXITCODE -ne 0) { throw "Tests failed" }
        Write-Host "✅ All tests passed" -ForegroundColor Green
    }
    catch {
        if (-not $Force) {
            Write-Host "❌ Tests failed: $_" -ForegroundColor Red
            Write-Host "Use -Force to deploy anyway" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "⚠️ Tests failed but continuing due to -Force flag" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n🧪 Step 2: Tests skipped" -ForegroundColor Yellow
}

# Step 3: Build Docker image (if not skipped)
if (-not $SkipBuild) {
    Write-Host "`n🏗️ Step 3: Building Docker image..." -ForegroundColor Yellow
    try {
        docker build -t "${ImageName}:${ImageTag}" .
        if ($LASTEXITCODE -ne 0) { throw "Docker build failed" }
        Write-Host "✅ Docker image built successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Docker build failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n🏗️ Step 3: Build skipped" -ForegroundColor Yellow
}

# Step 4: Deploy to registries
Write-Host "`n🚀 Step 4: Deploying to Azure Container Registries..." -ForegroundColor Yellow

function Deploy-ToRegistry {
    param(
        [string]$RegistryName,
        [string]$ImageName,
        [string]$ImageTag,
        [string]$TenantName
    )
    
    Write-Host "Deploying to $RegistryName ($TenantName)..." -ForegroundColor Cyan
    
    # Login to registry
    try {
        az acr login --name $RegistryName
        if ($LASTEXITCODE -ne 0) { throw "Registry login failed" }
    }
    catch {
        Write-Host "❌ Failed to login to $RegistryName" -ForegroundColor Red
        return $false
    }
    
    # Tag and push image
    try {
        $remoteTag = "${RegistryName}.azurecr.io/${ImageName}:${ImageTag}"
        docker tag "${ImageName}:${ImageTag}" $remoteTag
        docker push $remoteTag
        if ($LASTEXITCODE -ne 0) { throw "Push failed" }
        Write-Host "✅ Successfully deployed to $RegistryName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to push to $RegistryName : $_" -ForegroundColor Red
        return $false
    }
}

# Deploy to both registries
$registry1Success = Deploy-ToRegistry -RegistryName $RegistryName1 -ImageName $ImageName -ImageTag $ImageTag -TenantName "DEV.AF"
$registry2Success = Deploy-ToRegistry -RegistryName $RegistryName2 -ImageName $ImageName -ImageTag $ImageTag -TenantName "NEUMAN and ESSER"

# Step 5: Post-deployment verification
Write-Host "`n✅ Step 5: Post-deployment verification..." -ForegroundColor Yellow

if ($registry1Success) {
    Write-Host "Registry 1 Status: ✅ DEPLOYED" -ForegroundColor Green
    Write-Host "  URL: ${RegistryName1}.azurecr.io/${ImageName}:${ImageTag}" -ForegroundColor Cyan
}

if ($registry2Success) {
    Write-Host "Registry 2 Status: ✅ DEPLOYED" -ForegroundColor Green
    Write-Host "  URL: ${RegistryName2}.azurecr.io/${ImageName}:${ImageTag}" -ForegroundColor Cyan
}

# Step 6: Generate deployment report
Write-Host "`n📊 Step 6: Generating deployment report..." -ForegroundColor Yellow

$deploymentReport = @{
    "Timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "Environment" = $Environment
    "Image" = "${ImageName}:${ImageTag}"
    "Registry1" = @{
        "Name" = $RegistryName1
        "Status" = if ($registry1Success) { "SUCCESS" } else { "FAILED" }
        "URL" = "${RegistryName1}.azurecr.io/${ImageName}:${ImageTag}"
    }
    "Registry2" = @{
        "Name" = $RegistryName2
        "Status" = if ($registry2Success) { "SUCCESS" } else { "FAILED" }
        "URL" = "${RegistryName2}.azurecr.io/${ImageName}:${ImageTag}"
    }
}

$reportJson = $deploymentReport | ConvertTo-Json -Depth 3
$reportFile = "deployment-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$reportJson | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ Deployment report saved to: $reportFile" -ForegroundColor Green

# Final summary
Write-Host "`n🎉 Deployment Summary:" -ForegroundColor Green
Write-Host "Total registries: 2" -ForegroundColor White
$successCount = 0
$failCount = 0
if ($registry1Success) { $successCount++ } else { $failCount++ }
if ($registry2Success) { $successCount++ } else { $failCount++ }
Write-Host "Successful deployments: $successCount" -ForegroundColor White
Write-Host "Failed deployments: $failCount" -ForegroundColor White

if ($registry1Success -and $registry2Success) {
    Write-Host "🎯 All deployments successful!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️ Some deployments failed. Check the logs above." -ForegroundColor Yellow
    exit 1
}
