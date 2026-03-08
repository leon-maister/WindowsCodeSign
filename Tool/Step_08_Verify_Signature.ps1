Write-Host "Run Get-AuthenticodeSignature for " $env:file -ForegroundColor Blue
$sig = Get-AuthenticodeSignature $env:file
Write-Host "The Status: " $sig.Status
Write-Host "Status Message: " $sig.StatusMessage
Write-Host "Subject Message: " $sig.SignerCertificate.Subject
Write-Host "The Thumbprint: " $sig.SignerCertificate.Thumbprint
if ($sig.TimeStamperCertificate) {
Write-Host "TimeStamperCertificate.Subject: " $sig.TimeStamperCertificate.Subject }
Write-Host "-----"

Write-Host "Run Verify procedure for by signtool  for " $env:file -ForegroundColor Blue
signtool verify /pa /v $env:file