Write-Host "Setup Variables" -ForegroundColor Yellow
. "C:\Data\Signer\CertAuth\Step_0_Set_Env_Variables.ps1"

#akeyless auth-method create cert -n /WindowsCertAccess/CLI_Created_CertAccessForCodeSign --certificate-file-name ca_cert.pem --unique-identifier "CN"
#akeyless assoc-role-am --role-name /FullAccess  --am-name /WindowsCertAccess/CLI_Created_CertAccessForCodeSign 

Write-Host "Verify Cert on Akeyless" -ForegroundColor Blue
$resp = akeyless auth-method get -n /WindowsCertAccess/CertAccessForCodeSign --json | ConvertFrom-Json
[System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String($resp.access_info.cert_access_rules.certificate)
) | Out-File cert_from_akeyless.cer -Encoding ascii

#openssl x509 -in cert_from_akeyless.cer -text -noout

openssl x509 -in ca_cert.pem -outform DER -out ./ca_cert.der
openssl x509 -in cert_from_akeyless.cer -outform DER -out ./cert_from_akeyless.der

fc.exe /b ca_cert.der cert_from_akeyless.der > $null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Certificates are IDENTICAL" -ForegroundColor Green
}
else {
    Write-Host "Certificates mismatch. Aborting." -ForegroundColor Red
    exit 1
}

#cleanup storage

Write-Host "Cleanup Cert Store" -ForegroundColor Blue

@(
    "Cert:\LocalMachine\My",
    "Cert:\LocalMachine\Root",
    "Cert:\LocalMachine\CA",
    "Cert:\CurrentUser\My",
    "Cert:\CurrentUser\Root"
) | ForEach-Object {

    Write-Host "`nScanning $_ ..." -ForegroundColor Cyan

    $certs = Get-ChildItem $_ -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -like "*$env:client_CN*" }

    foreach ($cert in $certs) {
        Write-Host "Removing $($cert.Thumbprint) from $($cert.PSParentPath)" -ForegroundColor Yellow
        Remove-Item -Path $cert.PSPath -Force -ErrorAction SilentlyContinue
    }
}




openssl pkcs12 -export `
  -out $env:client_auth_pfx `
  -inkey $env:client_private_key `
  -in $env:client_certificate `
  -certfile $env:ca_cert `
  -name "AkeylessAuthCert" `
  -passout pass:qwerty


$sec = ConvertTo-SecureString "qwerty" -AsPlainText -Force

Import-PfxCertificate `
  -FilePath $env:client_auth_pfx `
  -CertStoreLocation "Cert:\LocalMachine\My" `
  -Password $sec `
| Select-Object Subject, Thumbprint, HasPrivateKey | Out-Host


#verify1
Write-Host "Testing cert in the Windows memory" -ForegroundColor Blue
Get-ChildItem Cert:\LocalMachine\My |
  Where-Object { $_.Subject -match $env:client_CN } |
  Select-Object Subject, Thumbprint, HasPrivateKey | Out-Host


#verify 2
openssl x509 -in $env:client_certificate -noout -fingerprint -sha1


# Sanity Check
$env:certPemB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($env:client_certificate))

# Get a challenge
$env:challenge = (akeyless get-cert-challenge --access-id $env:ACCESS_ID --cert-data $env:certPemB64 |
  Select-String '^Challenge:' | Select-Object -First 1).Line.Split(':')[1].Trim()

# Sign decoded challenge bytes with RSA-SHA256 using the PEM key (reference behavior)
[IO.File]::WriteAllBytes($env:challenge_bin, [Convert]::FromBase64String($env:challenge))

openssl dgst -sha256 -sign $env:client_private_key -out $env:sig_bin $env:challenge_bin

$env:sigB64 = (openssl base64 -A -in $env:sig_bin).Trim()

echo $env:ACCESS_ID

# Authenticate (should return a token)
akeyless auth --access-id $env:ACCESS_ID --access-type cert --cert-data $env:certPemB64 --cert-challenge $env:challenge --signed-cert-challenge $env:sigB64


