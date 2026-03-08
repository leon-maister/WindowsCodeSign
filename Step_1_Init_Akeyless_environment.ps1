# =========================================================
# Step_1_Init_Akeyless_environment.ps1
# Conf is ALWAYS enabled (no parameter)
# =========================================================

Write-Host "Conf is enabled - using configuration file for DFC key creation." -ForegroundColor Cyan

# =========================================================
# 1. Check that all required environment variables are defined
# =========================================================

Write-Host "Checking required environment variables..." -ForegroundColor Cyan

$requiredVars = @(
    "Sign_Mode",
    "DLL_Signer_key",
    "Cert_Signer_Key",
    "PKI_DLL_Issuer",
    "Cert_destination_path",
    "Common_Name",
    "CSR_File",
    "CERT_File"
)

foreach ($var in $requiredVars) {
    $value = [System.Environment]::GetEnvironmentVariable($var)
    if (-not $value) {
        Write-Error "Missing environment variable: $var"
        exit 1
    }
}

Write-Host "All required environment variables are set." -ForegroundColor Green
Write-Host "Config File is used:" -ForegroundColor Blue
cat csr.conf
# =========================================================
# 2. Check if DLL_Signer_key exists in Akeyless. If not, create it.
# =========================================================

Write-Host "Checking if key $env:DLL_Signer_key exists in Akeyless..." -ForegroundColor Magenta
$keyExists = akeyless list-items | Select-String -SimpleMatch $env:DLL_Signer_key

if ($null -eq $keyExists) {
    Write-Host "Key not found. Creating new DFC key: $env:DLL_Signer_key" -ForegroundColor Yellow

    $createCmd = "akeyless create-dfc-key --profile default --name $env:DLL_Signer_key --alg RSA2048 --split-level 2 --certificate-ttl 30 --certificate-common-name $env:Common_Name --generate-self-signed-certificate true --conf-file-path csr.conf"

    Write-Host "Running command: $createCmd" -ForegroundColor Cyan
    iex $createCmd

    Write-Host "DFC key created successfully: $env:DLL_Signer_key" -ForegroundColor Green
}
else {
    Write-Host "Key already exists in Akeyless: $env:DLL_Signer_key" -ForegroundColor Green
}

# =========================================================
# 3. Wait 1 second, then generate CSR for Cert_Signer_Key
# =========================================================

Start-Sleep -Seconds 1
Write-Host "Generating CSR for key: $env:Cert_Signer_Key" -ForegroundColor Magenta

# Keep the pipeline in the string exactly as-is
$csrCmd = "akeyless generate-csr --profile default --split-level 2 --name $env:Cert_Signer_Key --generate-key --key-type dfc --alg RSA4096 --common-name $env:Common_Name | Out-File -Encoding ascii $env:CSR_File"

Write-Host "Running command: $csrCmd" -ForegroundColor Cyan
iex $csrCmd

Write-Host "CSR generated successfully and saved to: $env:CSR_File" -ForegroundColor Green

# =========================================================
# 4. Check if PKI_DLL_Issuer exists. If not, create it.
# =========================================================

Write-Host "Checking if PKI Certificate Issuer $env:PKI_DLL_Issuer exists in Akeyless..." -ForegroundColor Magenta
$issuerExists = akeyless list-items | Select-String -SimpleMatch $env:PKI_DLL_Issuer

if ($null -eq $issuerExists) {
    Write-Host "PKI Certificate Issuer not found. Creating new issuer: $env:PKI_DLL_Issuer" -ForegroundColor Yellow

    $createIssuerCmd = "akeyless create-pki-cert-issuer --profile default --name $env:PKI_DLL_Issuer --allowed-domains $env:Common_Name --signer-key-name $env:DLL_Signer_key --code-signing-flag --key-usage DigitalSignature --critical-key-usage true --ttl 600d --destination-path $env:Cert_destination_path"

    Write-Host "Running command: $createIssuerCmd" -ForegroundColor Cyan
    iex $createIssuerCmd

    Write-Host "PKI Certificate Issuer created successfully: $env:PKI_DLL_Issuer" -ForegroundColor Green

    $checkSigningFlagCmd = "(akeyless describe-item --name $env:PKI_DLL_Issuer --json | ConvertFrom-Json).certificate_issue_details.pki_cert_issuer_details.code_signing_flag"

    Write-Host "Checking code_signing_flag on issuer (should be True):" -ForegroundColor Blue
    iex $checkSigningFlagCmd
}
else {
    Write-Host "PKI Certificate Issuer already exists: $env:PKI_DLL_Issuer" -ForegroundColor Green
}

# =========================================================
# 5. Wait 1 second, then request certificate signing
# =========================================================

Start-Sleep -Seconds 1
Write-Host "Requesting certificate from Akeyless PKI Issuer: $env:PKI_DLL_Issuer" -ForegroundColor Magenta

$issueCertCmd = "akeyless get-pki-certificate --profile default --cert-issuer-name $env:PKI_DLL_Issuer --extended-key-usage codesigning --csr-file-path $env:CSR_File > $env:CERT_File"

Write-Host "Running command: $issueCertCmd" -ForegroundColor Cyan
iex $issueCertCmd

if (Test-Path $env:CERT_File) {
    Write-Host "Certificate saved to: $env:CERT_File" -ForegroundColor Green
}
else {
    Write-Error "Certificate file was not created: $env:CERT_File"
    exit 1
}

Write-Host "Done." -ForegroundColor Green
