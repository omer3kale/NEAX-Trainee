# Request for Azure DevOps Access - NEA X GmbH
## Docker Container Deployment Project

### Project Overview
This document outlines the requirements for setting up CI/CD pipelines for Docker container deployments to Azure Container Registries.

### Current Status
✅ **Completed Successfully:**
- Docker image built from .NET 8.0 ASP.NET Core application
- Manual deployment to both Azure Container Registries:
  - `acraz2003cah25oct.azurecr.io` (DEV.AF tenant)
  - `acraz2003ou17juli.azurecr.io` (NEUMAN & ESSER tenant)
- Authentication issues resolved (Error Code 53003)
- Enhanced PowerShell automation scripts created

### Request for IT Admin

#### 1. **Azure DevOps Organization Access**
**Issue:** Cannot create new Azure DevOps organizations due to corporate policy
**Request:** Please provide access to the existing NEA X GmbH Azure DevOps organization or create a project within it

**Required Permissions:**
- Project creation rights
- Pipeline creation and editing
- Service connection management
- Repository access

#### 2. **Service Connections Required**
Please set up the following service connections in Azure DevOps:

**Service Connection 1: DEV.AF Tenant**
- Name: `AzureContainerRegistry-DEV-AF`
- Type: Azure Resource Manager
- Subscription: `9b7860bb-19cc-428f-ad31-3e38fd5d4d9c`
- Resource Group: (as per DEV.AF setup)
- Registry: `acraz2003cah25oct.azurecr.io`

**Service Connection 2: NEUMAN & ESSER Tenant**
- Name: `AzureContainerRegistry-NEUMAN-ESSER`
- Type: Azure Resource Manager
- Subscription: `9e89f2d0-f39d-4ade-aa60-23ee14a02deb`
- Resource Group: (as per NEUMAN & ESSER setup)
- Registry: `acraz2003ou17juli.azurecr.io`

#### 3. **Pipeline Configuration**
**Repository:** `https://github.com/omer3kale/NEA-X-Msoft-Projects`
**Branch:** `master`
**Build Agent:** Microsoft-hosted Ubuntu latest

**Pipeline Requirements:**
- Build .NET 8.0 ASP.NET Core application
- Run unit tests
- Build Docker image
- Push to both Azure Container Registries
- Generate deployment reports

#### 4. **Security Considerations**
- All credentials are managed through Azure Key Vault
- Service principals use minimal required permissions
- Container images are scanned for vulnerabilities
- Deployment approvals for production environments

#### 5. **Alternative Solutions**
If Azure DevOps organization access is not possible, we have implemented:
- GitHub Actions workflow (ready to use)
- Local CI/CD PowerShell scripts
- Manual deployment procedures with error handling

### Technical Details

**Docker Image:**
- Name: `aspnetcorecontainer`
- Base: Microsoft .NET 8.0 ASP.NET Core
- Size: ~325MB
- Features: Weather Forecast API, Swagger documentation

**Current Deployment URLs:**
- DEV.AF: `acraz2003cah25oct.azurecr.io/aspnetcorecontainer:latest`
- NEUMAN & ESSER: `acraz2003ou17juli.azurecr.io/aspnetcorecontainer:latest`

### Files Created
1. `push-to-acr.ps1` - Enhanced multi-registry deployment script
2. `ci-cd-pipeline.ps1` - Local CI/CD automation
3. `troubleshoot-azure-auth.ps1` - Authentication diagnostics
4. `.github/workflows/docker-deploy.yml` - GitHub Actions workflow
5. `deployment-summary.ps1` - Deployment reporting

### Next Steps
1. **Immediate:** Use local scripts for continued development
2. **Short-term:** Set up GitHub Actions if Azure DevOps is not available
3. **Long-term:** Implement full CI/CD pipeline once organizational access is granted

### Contact Information
**Developer:** Ömer Üçkale (OU@nea-x.net)
**Repository:** NEA-X-Msoft-Projects
**Project:** AZ2003 - Docker Container Deployment

---

**Note:** This project successfully demonstrates multi-tenant Docker deployment capabilities and can be immediately productionized with proper CI/CD access.
