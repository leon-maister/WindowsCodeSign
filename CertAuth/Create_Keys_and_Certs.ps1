
# create the private key for CA
openssl genrsa -out $env:ca_private_key 2048


# Root CA self-signed certificate
openssl req -x509 -new -key $env:ca_private_key -sha256 -days 3650 `
  -out $env:ca_cert `
  -subj "/C=US/O=Example/OU=Apps/CN=AkeylessSign"


openssl genrsa -out $env:client_private_key 2048

openssl req -new -key $env:client_private_key -out $env:client_csr `
  -subj "/C=US/O=Example/OU=Apps/CN=$env:client_CN"


openssl x509 -req -in $env:client_csr `
  -CA $env:ca_cert -CAkey $env:ca_private_key -CAcreateserial `
  -out $env:client_certificate `
  -days 3650 -sha256


