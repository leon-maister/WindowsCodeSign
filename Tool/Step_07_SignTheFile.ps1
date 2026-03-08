$env:file = "C:\Data\Signer\DLL_For_Sign\TestLibrary.dll"
$env:backupFile = "C:\Data\Signer\BackupDLL\TestLibrary.dll"

Write-Host "Sign File: $env:file" -ForegroundColor Blue
Write-Host "Using thumb: $env:thumb" -ForegroundColor Blue

# Check if file has any signature (even invalid)
$signature = Get-AuthenticodeSignature $env:file

if ($signature.Status -ne 'NotSigned') {
    Write-Host "File has a signature (valid or invalid). Restoring from backup..." -ForegroundColor Yellow
    Copy-Item -Path $env:backupFile -Destination $env:file -Force
    Write-Host "File restored from backup: $env:backupFile -> $env:file" -ForegroundColor Cyan
}

# Always proceed to signing
Write-Host "Proceeding with signing..." -ForegroundColor Yellow

signtool sign /debug /v /sm /s My /sha1 $env:thumb /fd SHA256 `
  /tr "http://timestamp.digicert.com" /td SHA256 `
  $env:file

if ($LASTEXITCODE -eq 0) {
    Write-Host "sign exit=$LASTEXITCODE" -ForegroundColor Green
} 
else {
    Write-Host "sign exit=$LASTEXITCODE" -ForegroundColor Red
}
