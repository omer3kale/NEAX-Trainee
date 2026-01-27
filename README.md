# NEAX-Trainee

## 🔐 Security Notice

This repository contains Azure deployment scripts with secure credential management. **Never commit passwords or secrets to version control.**

### Quick Security Setup

For Azure Container Registry deployments, configure credentials using one of these methods:

**Option 1 - Environment Variables** (Recommended for local development):
```powershell
$env:AZURE_ACR_USERNAME_NEA = "acraz2003ou17juli"
$env:AZURE_ACR_PASSWORD_NEA = "your_password"
```

**Option 2 - Azure Key Vault** (Recommended for production):
```powershell
$env:AZURE_KEY_VAULT_NAME = "your-keyvault-name"
```

**Option 3 - Azure CLI** (Easiest):
```bash
az login
```

📖 **Complete security guide**: See [AZURE_SECURITY_GUIDE.md](AZURE_SECURITY_GUIDE.md)

---

SA AS!!!
