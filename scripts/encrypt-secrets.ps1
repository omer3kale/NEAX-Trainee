# PowerShell Secret Encryption Utility
# Encrypts and decrypts sensitive data using Windows Data Protection API (DPAPI)

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Encrypt", "Decrypt")]
    [string]$Action = "Encrypt",
    
    [Parameter(Mandatory=$false)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$PlainText,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseBase64
)

function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Error { param([string]$Message) Write-Host "✗ $Message" -ForegroundColor Red }

# Encrypt a string using DPAPI
function Encrypt-String {
    param([string]$PlainText)
    
    try {
        $secureString = ConvertTo-SecureString -String $PlainText -AsPlainText -Force
        $encrypted = ConvertFrom-SecureString -SecureString $secureString
        
        if ($UseBase64) {
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($encrypted)
            return [Convert]::ToBase64String($bytes)
        }
        
        return $encrypted
    }
    catch {
        Write-Error "Encryption failed: $_"
        exit 1
    }
}

# Decrypt a string using DPAPI
function Decrypt-String {
    param([string]$EncryptedText)
    
    try {
        if ($UseBase64) {
            $bytes = [Convert]::FromBase64String($EncryptedText)
            $EncryptedText = [System.Text.Encoding]::Unicode.GetString($bytes)
        }
        
        $secureString = ConvertTo-SecureString -String $EncryptedText
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        
        return $plainText
    }
    catch {
        Write-Error "Decryption failed: $_"
        exit 1
    }
}

# Main execution
Write-Host ""
Write-Host "=== PowerShell Secret Encryption Utility ===" -ForegroundColor Green
Write-Host ""

if ($Action -eq "Encrypt") {
    if ($InputFile) {
        Write-Info "Reading from file: $InputFile"
        if (-not (Test-Path $InputFile)) {
            Write-Error "Input file not found: $InputFile"
            exit 1
        }
        $PlainText = Get-Content -Path $InputFile -Raw
    }
    elseif (-not $PlainText) {
        $secureInput = Read-Host "Enter text to encrypt" -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput)
        $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    
    Write-Info "Encrypting text..."
    $encrypted = Encrypt-String -PlainText $PlainText
    
    # Clear sensitive data from memory
    $PlainText = $null
    [System.GC]::Collect()
    
    if ($OutputFile) {
        $encrypted | Out-File -FilePath $OutputFile -NoNewline
        Write-Success "Encrypted text saved to: $OutputFile"
    }
    else {
        Write-Host ""
        Write-Host "Encrypted Text:" -ForegroundColor Yellow
        Write-Host $encrypted -ForegroundColor Cyan
        Write-Host ""
    }
}
elseif ($Action -eq "Decrypt") {
    if ($InputFile) {
        Write-Info "Reading from file: $InputFile"
        if (-not (Test-Path $InputFile)) {
            Write-Error "Input file not found: $InputFile"
            exit 1
        }
        $EncryptedText = Get-Content -Path $InputFile -Raw
    }
    elseif (-not $PlainText) {
        $EncryptedText = Read-Host "Enter encrypted text"
    }
    else {
        $EncryptedText = $PlainText
    }
    
    Write-Info "Decrypting text..."
    $decrypted = Decrypt-String -EncryptedText $EncryptedText
    
    if ($OutputFile) {
        $decrypted | Out-File -FilePath $OutputFile -NoNewline
        Write-Success "Decrypted text saved to: $OutputFile"
    }
    else {
        Write-Host ""
        Write-Host "Decrypted Text:" -ForegroundColor Yellow
        Write-Host $decrypted -ForegroundColor Cyan
        Write-Host ""
    }
}

Write-Host ""
Write-Host "=== SECURITY NOTES ===" -ForegroundColor Yellow
Write-Host "• DPAPI encryption is user and machine-specific" -ForegroundColor White
Write-Host "• Encrypted data can only be decrypted on the same machine by the same user" -ForegroundColor White
Write-Host "• Use Azure Key Vault for production deployments" -ForegroundColor White
Write-Host "• Never commit encrypted secrets to version control" -ForegroundColor White
Write-Host ""
