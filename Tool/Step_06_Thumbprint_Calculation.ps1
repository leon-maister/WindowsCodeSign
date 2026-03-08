param(
    [switch]$all
)

# List all certs in multiple stores
@(
  "Cert:\LocalMachine\My",
  "Cert:\LocalMachine\Root",
  "Cert:\LocalMachine\CA",
  "Cert:\CurrentUser\My",
  "Cert:\CurrentUser\Root"
) | ForEach-Object {
    Write-Host "`nListing certificates in $_ ..." -ForegroundColor Cyan

    if ($all) {
        # Show all certificates
        Write-Host "Displaying all certificates..." -ForegroundColor Yellow
        Get-ChildItem $_ -ErrorAction SilentlyContinue |
            Select-Object Subject, Thumbprint, NotAfter, HasPrivateKey |
            Format-Table -Auto
    } else {
        # Show only -like "*$env:Common_Name*"
        Write-Host "Displaying only certificates for $env:Common_Name " -ForegroundColor Green
        Get-ChildItem $_ -ErrorAction SilentlyContinue |
            Where-Object { $_.Subject -like "*$env:Common_Name*" } |
            Select-Object Subject, Thumbprint, NotAfter, HasPrivateKey |
            Format-Table -Auto
    }
}

# Last Added (always filtered by "*$env:Common_Name*")
$env:thumb = (
    Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.Subject -like "*$env:Common_Name*" -and $_.HasPrivateKey } |
    Sort-Object NotAfter |
    Select-Object -Last 1 -ExpandProperty Thumbprint
)

Write-Host "Thumbprint: $env:thumb"

Write-Host "Confirm the certificate is bound to the provider:"
(Get-Item "Cert:\LocalMachine\My\$env:thumb").HasPrivateKey
certutil -store -v My $env:thumb | findstr /i "Provider Container"
