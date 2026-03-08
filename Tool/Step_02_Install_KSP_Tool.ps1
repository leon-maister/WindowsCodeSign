msiexec /i "$env:msi" IMPORT_CERT=0 /l*v "$env:logInstall"
$LASTEXITCODE