# -------------------------------
# 1. Persistent environment setup
# -------------------------------

# Make sure persistent Akeyless variables exist (user-level)
if (-not [Environment]::GetEnvironmentVariable("msi", "User")) {
    [Environment]::SetEnvironmentVariable("msi", "C:\Data\Signer\Tool\AkeylessKspInstaller\AkeylessKspInstaller.msi", "User")
}
if (-not [Environment]::GetEnvironmentVariable("prov", "User")) {
    [Environment]::SetEnvironmentVariable("prov", "Akeyless KSP", "User")
}

if (-not [Environment]::GetEnvironmentVariable("helper", "User")) {
    [Environment]::SetEnvironmentVariable("helper", "C:\Program Files\Akeyless\Akeyless KSP\akeyless-ksp-cert-helper.exe", "User")
}
if (-not [Environment]::GetEnvironmentVariable("configFile", "User")) {
    [Environment]::SetEnvironmentVariable("configFile", "C:\Data\Signer\Tool\Config\sqlcrypt.conf", "User")
}

# -------------------------------
# 2. Load environment variables
# -------------------------------

$env:msi        = [Environment]::GetEnvironmentVariable("msi", "User")
$env:prov       = [Environment]::GetEnvironmentVariable("prov", "User")
$env:helper     = [Environment]::GetEnvironmentVariable("helper", "User")
$env:configFile = [Environment]::GetEnvironmentVariable("configFile", "User")
$env:AKEYLESS_SQLCRYPT_CONFIG_PATH = [Environment]::GetEnvironmentVariable("configFile", "User")


# Create temporary log paths for current session
$env:logInstall = "C:\Data\Signer\Tool\AkeylessKspInstaller\AkeylessKspInstall.log"
$env:logUninst  = "C:\Data\Signer\Tool\AkeylessKspInstaller\AkeylessKspUninstall.log"

& "C:\Data\Signer\Step_0_Set_Env_Variables.ps1"


# -------------------------------
# 4. Display confirmation message
# -------------------------------

Write-Host "  Akeyless KSP environment loaded" -ForegroundColor Green
Write-Host "  Sign_Mode: $env:Sign_Mode" -ForegroundColor Blue
Write-Host "  MSI path:        $env:msi"
Write-Host "  Provider name:   $env:prov"
Write-Host "  Helper path:     $env:helper"
Write-Host "  Config file:     $env:configFile"
Write-Host "  Install log:     $env:logInstall"
Write-Host "  Uninstall log:   $env:logUninst"
Write-Host ""
