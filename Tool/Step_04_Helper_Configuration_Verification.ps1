@($env:helper, $env:configFile) | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "Found:" $_ -ForegroundColor Green
    } else {
        Write-Host "Missing:" $_ -ForegroundColor Red
    }
}

& $env:helper --config-path  $env:configFile sync-cert --dry-run