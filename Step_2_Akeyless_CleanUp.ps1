param(
    [switch]$DryRun
)

# =========================================================
# Script cleanup for Akeyless environment
# =========================================================

# 1. Check that all required environment variables are defined
Write-Host "Checking required environment variables..." -ForegroundColor Cyan

$requiredVars = @(
    "Cert_destination_path",
    "PKI_DLL_Issuer",
    "DLL_Signer_key",
    "Cert_Signer_Key"
)

foreach ($var in $requiredVars) {
    $value = [System.Environment]::GetEnvironmentVariable($var)
    if (-not $value) {
        Write-Warning "Missing environment variable: $var - skipping related actions."
    }
}

Write-Host "Environment variable validation complete." -ForegroundColor Green

# =========================================================
# 2. Check if Cert_destination_path exists and list/delete items under it
# =========================================================

Write-Host "Checking for items under path $env:Cert_destination_path ..." -ForegroundColor Cyan

$jsonOutput = akeyless list-items --path $env:Cert_destination_path | ConvertFrom-Json

if ($jsonOutput.items.Count -gt 0) {
    Write-Host "Found items under $env:Cert_destination_path:" -ForegroundColor Cyan

    foreach ($item in $jsonOutput.items) {
        if ($DryRun) {
            Write-Host "Item will be deleted: $($item.item_name)" -ForegroundColor Yellow
        }
        else {
            Write-Host "Deleting item: $($item.item_name)" -ForegroundColor Red
            akeyless delete-item --profile default --name $item.item_name | Out-Null
        }
    }

    Write-Host "Finished processing items under $env:Cert_destination_path." -ForegroundColor Green
}
else {
    Write-Host "No items found under $env:Cert_destination_path." -ForegroundColor Green
}

# =========================================================
# 3. Check if PKI_DLL_Issuer exists and delete if not DryRun
# =========================================================

if ($env:PKI_DLL_Issuer) {
    Write-Host "Checking if PKI Certificate Issuer $env:PKI_DLL_Issuer exists in Akeyless..." -ForegroundColor Cyan
    $issuerExists = akeyless list-items | Select-String -SimpleMatch $env:PKI_DLL_Issuer

    if ($null -ne $issuerExists) {
        if ($DryRun) {
            Write-Host "Item will be deleted: $env:PKI_DLL_Issuer" -ForegroundColor Yellow
        }
        else {
            Write-Host "Deleting item: $env:PKI_DLL_Issuer" -ForegroundColor Red
            akeyless delete-item --profile default --name $env:PKI_DLL_Issuer | Out-Null
        }
    }
    else {
        Write-Host "PKI Issuer $env:PKI_DLL_Issuer does not exist. Nothing to delete." -ForegroundColor Green
    }
}

# =========================================================
# 4. Check if DLL_Signer_key exists and delete if not DryRun
# =========================================================

if ($env:DLL_Signer_key) {
    Write-Host "Checking if key $env:DLL_Signer_key exists in Akeyless..." -ForegroundColor Cyan
    $keyExists = akeyless list-items | Select-String -SimpleMatch $env:DLL_Signer_key

    if ($null -ne $keyExists) {
        if ($DryRun) {
            Write-Host "Item will be deleted: $env:DLL_Signer_key" -ForegroundColor Yellow
        }
        else {
            Write-Host "Deleting item immediately: $env:DLL_Signer_key" -ForegroundColor Red
            akeyless delete-item --profile default --name $env:DLL_Signer_key --delete-immediately --delete-in-days=-1 | Out-Null
        }
    }
    else {
        Write-Host "Key $env:DLL_Signer_key does not exist. Nothing to delete." -ForegroundColor Green
    }
}

# =========================================================
# 5. Check if Cert_Signer_Key exists and delete if not DryRun
# =========================================================

if ($env:Cert_Signer_Key) {
    Write-Host "Checking if Cert_Signer_Key $env:Cert_Signer_Key exists in Akeyless..." -ForegroundColor Cyan
    $certKeyExists = akeyless list-items | Select-String -SimpleMatch $env:Cert_Signer_Key

    if ($null -ne $certKeyExists) {
        if ($DryRun) {
            Write-Host "Item will be deleted: $env:Cert_Signer_Key" -ForegroundColor Yellow
        }
        else {
            Write-Host "Deleting item: $env:Cert_Signer_Key" -ForegroundColor Red
            akeyless delete-item --profile default --name $env:Cert_Signer_Key --delete-immediately --delete-in-days=-1 | Out-Null
        }
    }
    else {
        Write-Host "Cert_Signer_Key $env:Cert_Signer_Key does not exist. Nothing to delete." -ForegroundColor Green
    }
}

# =========================================================
# 6. Summary
# =========================================================

if ($DryRun) {
    Write-Host "Dry-run completed successfully. No changes made." -ForegroundColor Green
}
else {
    Write-Host "Cleanup executed successfully." -ForegroundColor Green
}
