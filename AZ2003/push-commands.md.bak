# Manual Commands to Push Docker Image to Azure Container Registry

## Prerequisites
- Azure Container Registry: acraz2003cah25oct.azurecr.io
- Subscription: DEV.AF (9b7860bb-19cc-428f-ad31-3e38fd5d4d9c)
- Resource Group: rg-az2003-containers
- Docker Image: aspnetcorecontainer:latest

## Commands to Run (in order):

### 1. Login to Azure Container Registry
```powershell
az acr login --name acraz2003cah25oct --subscription 9b7860bb-19cc-428f-ad31-3e38fd5d4d9c
```

### 2. Tag the image for Azure Container Registry
```powershell
docker tag aspnetcorecontainer:latest acraz2003cah25oct.azurecr.io/aspnetcorecontainer:latest
```

### 3. Push the image to Azure Container Registry
```powershell
docker push acraz2003cah25oct.azurecr.io/aspnetcorecontainer:latest
```

### 4. Verify the image was pushed successfully
```powershell
az acr repository show --name acraz2003cah25oct --repository aspnetcorecontainer --subscription 9b7860bb-19cc-428f-ad31-3e38fd5d4d9c
```

### 5. List all images in the repository
```powershell
az acr repository list --name acraz2003cah25oct --subscription 9b7860bb-19cc-428f-ad31-3e38fd5d4d9c
```

## Alternative: Using Docker CLI directly
If you prefer to use Docker CLI login instead of Azure CLI:

```powershell
# Get access token
$token = az acr login --name acraz2003cah25oct --expose-token --subscription 9b7860bb-19cc-428f-ad31-3e38fd5d4d9c --query accessToken --output tsv

# Login to Docker with the token
echo $token | docker login acraz2003cah25oct.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password-stdin

# Then push
docker push acraz2003cah25oct.azurecr.io/aspnetcorecontainer:latest
```

## Current Status
✅ Docker image built: aspnetcorecontainer:latest
✅ Azure Container Registry created: acraz2003cah25oct.azurecr.io
✅ Resource group created: rg-az2003-containers
⚠️ Network connectivity issue - commands ready to run when resolved

## Next Steps
1. Resolve network connectivity issues
2. Run the commands above in order
3. Verify the image push was successful
4. Test pulling the image from ACR
