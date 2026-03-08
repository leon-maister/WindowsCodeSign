@(
    "Cert:\LocalMachine\My",
    "Cert:\LocalMachine\Root",
    "Cert:\LocalMachine\CA",
    "Cert:\CurrentUser\My",
    "Cert:\CurrentUser\Root"
) | ForEach-Object {
    Write-Host "`nScanning $_ ..." -ForegroundColor Cyan
    $certs = Get-ChildItem $_ -ErrorAction SilentlyContinue |
      Where-Object { $_.Subject -like "*$env:Common_Name*" } |
      ForEach-Object { $_ }  # 
         foreach ($cert in $certs) {
            Write-Host "Removing $($cert.Thumbprint) from $($cert.PSParentPath)" -ForegroundColor Yellow
            Remove-Item -Path $cert.PSPath -Force -ErrorAction SilentlyContinue
      }

}

@($env:helper, $env:configFile) | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "Found:" $_ -ForegroundColor Green
    } else {
        Write-Host "Missing:" $_ -ForegroundColor Red
    }
}

& $env:helper --config-path  $env:configFile sync-cert --store-scope machine --store-name My

# ============================================================
# Run another PowerShell script from this script
# ============================================================

$bringRootScript = "C:\Data\Signer\Step_3_Bring_Root_Certificate.ps1"

if (Test-Path $bringRootScript) {
    Write-Host "`nRunning secondary script: $bringRootScript" -ForegroundColor Cyan
    & powershell -ExecutionPolicy Bypass -File $bringRootScript
    Write-Host "Secondary script finished successfully." -ForegroundColor Green
} else {
    Write-Host "`nCannot find script: $bringRootScript" -ForegroundColor Red
}
