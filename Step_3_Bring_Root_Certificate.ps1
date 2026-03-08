if ($env:Sign_Mode -eq "OpenSSL") {
    $itemName = $env:OpenSSL_DLL_Signer_key
} else {
    $itemName = $env:DLL_Signer_key
}

(akeyless describe-item --name $itemName --json | ConvertFrom-Json).certificates | Out-File "C:\Data\Signer\RootKeyCert\dfc_root_key_ca.cer"
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("C:\Data\Signer\RootKeyCert\dfc_root_key_ca.cer")

Write-Host "Mode: $env:Sign_Mode" -ForegroundColor Cyan
Write-Host "Subject: $($cert.Subject)"
Write-Host "Issuer: $($cert.Issuer)"
Write-Host "Valid From: $($cert.NotBefore)"
Write-Host "Valid To: $($cert.NotAfter)"

certutil -dump "C:\Data\Signer\RootKeyCert\dfc_root_key_ca.cer"
certutil -addstore -f "Root" "C:\Data\Signer\RootKeyCert\dfc_root_key_ca.cer"



#(akeyless describe-item --name $env:DLL_Signer_key --json | ConvertFrom-Json).certificates | Out-File $env:Root_Key_Cert_Path
#certutil -dump $env:Root_Key_Cert_Path
#certutil -addstore -f "Root" $env:Root_Key_Cert_Path