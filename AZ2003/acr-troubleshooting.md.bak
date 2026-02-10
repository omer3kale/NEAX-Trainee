# Azure Container Registry Push - Troubleshooting Guide

## Current Status
- ✅ Docker image built: aspnetcorecontainer:latest
- ✅ Docker image tagged: acraz2003cah25oct.azurecr.io/aspnetcorecontainer:latest
- ✅ Azure Container Registry created: acraz2003cah25oct.azurecr.io
- ❌ Admin user not enabled on ACR
- ❌ Network connectivity issues with Azure CLI

## Problem: Admin User Not Enabled

The Azure Container Registry was created but the admin user is not enabled, which is required for username/password authentication.

## Solution Options:

### Option 1: Enable Admin User via Azure Portal (Recommended)
1. Go to Azure Portal: https://portal.azure.com
2. Navigate to your Container Registry: acraz2003cah25oct
3. In the subscription: DEV.AF (9b7860bb-19cc-428f-ad31-3e38fd5d4d9c)
4. Go to Settings > Access keys
5. Toggle "Admin user" to "Enabled"
6. Copy the Username and Password (or Password2)
7. Use these credentials to login:
   ```powershell
   docker login acraz2003cah25oct.azurecr.io --username <username> --password <password>
   ```

### Option 2: Enable Admin User via Azure CLI (when network is stable)
```powershell
az acr update --name acraz2003cah25oct --admin-enabled true --subscription 9b7860bb-19cc-428f-ad31-3e38fd5d4d9c
```

Then get the credentials:
```powershell
az acr credential show --name acraz2003cah25oct --subscription 9b7860bb-19cc-428f-ad31-3e38fd5d4d9c
```

### Option 3: Use Service Principal Authentication (Advanced)
If you prefer not to use admin credentials, you can create a service principal with ACR permissions.

## Once Admin User is Enabled:

1. **Login to Docker:**
   ```powershell
   docker login acraz2003cah25oct.azurecr.io --username <admin_username> --password <admin_password>
   ```

2. **Push the Image:**
   ```powershell
   docker push acraz2003cah25oct.azurecr.io/aspnetcorecontainer:latest
   ```

3. **Verify the Push:**
   ```powershell
   az acr repository list --name acraz2003cah25oct --subscription 9b7860bb-19cc-428f-ad31-3e38fd5d4d9c
   ```

## Alternative: Use VS Code Docker Extension

1. Open VS Code Command Palette (Ctrl+Shift+P)
2. Run: "Docker Images: Push"
3. Select: acraz2003cah25oct.azurecr.io/aspnetcorecontainer:latest
4. Follow the prompts to connect to Azure Container Registry

## Current Network Issues
- Azure CLI is experiencing connection resets
- This is likely a temporary network issue
- Try the commands later or use the Azure Portal approach

## Next Steps
1. Enable admin user via Azure Portal (fastest method)
2. Get the actual admin credentials
3. Login to Docker with the real credentials
4. Push the image
5. Verify the push was successful

## Resources
- Azure Container Registry: https://acraz2003cah25oct.azurecr.io
- Subscription: DEV.AF (9b7860bb-19cc-428f-ad31-3e38fd5d4d9c)
- Resource Group: rg-az2003-containers
- Location: East US
