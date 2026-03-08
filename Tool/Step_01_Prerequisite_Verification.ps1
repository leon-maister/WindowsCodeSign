Write-Host "Environment variable 'msi' set to:" $env:msi -ForegroundColor Green
Write-Host "Environment variable 'prov' set to:" $env:prov -ForegroundColor Green
Write-Host "Log (install):" $env:logInstall
Write-Host "Log (uninstall):" $env:logUninst
Write-Host "ConfigFile:" $env:AKEYLESS_SQLCRYPT_CONFIG_PATH

# =========================================================
# Detect or register path to signtool.exe automatically
# =========================================================

# Step 1: Check if signtool.exe already exists in any folder from PATH
$found = $null
$pathParts = $env:Path -split ';'

foreach ($p in $pathParts) {
    # Skip empty or whitespace-only entries
    if ([string]::IsNullOrWhiteSpace($p)) { continue }

    $possiblePath = Join-Path $p "signtool.exe"
    if (Test-Path $possiblePath) {
        $found = $possiblePath
        break
    }
}

if ($found) { Write-Host "signtool.exe found in PATH: $found" -ForegroundColor Green}

else {
    Write-Host "signtool.exe not found in PATH. Searching on disk..."

    # Step 2: Search signtool.exe under Windows SDK installation folders
    $searchPath = "C:\Program Files (x86)\Windows Kits"
    $signtool = Get-ChildItem $searchPath -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match "x64" } |
                Select-Object -First 1 -ExpandProperty FullName

    if ($signtool) {
        Write-Host "Found signtool.exe at:"
        Write-Host "  $signtool"

        # Step 3: Add its folder to PATH for the current PowerShell session
        $signtoolFolder = Split-Path $signtool -Parent
        $env:Path += ";$signtoolFolder"
        Write-Host "Temporarily added to PATH for this session."
    }
    else {
        Write-Host "signtool.exe not found anywhere under $searchPath."
    }
}

# Step 4: Verify that signtool is now accessible
if (Get-Command signtool.exe -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "Signtool is now available."
} else {
    Write-Host ""
    Write-Host "Signtool is still not available."
}
