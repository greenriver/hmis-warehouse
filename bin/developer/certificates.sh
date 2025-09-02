#!/bin/bash

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <dev-domain> <traefik-path>"
    echo "Example: $0 example.local /path/to/traefik"
    exit 1
fi

DOMAIN="$1"
TRAEFIK="$2"

echo "Generating SSL certificates for domain: $DOMAIN"
echo "Using traefik path: $TRAEFIK"

# Navigate to traefik directory and create necessary directories
cd "$TRAEFIK"
mkdir -p traefik/tools/certs
mkdir -p traefik/tools/traefik
cd traefik

# Copy configuration files
cp ../../hmis-warehouse/docs/traefik/docker-compose.sample.yml docker-compose.yml
cp ../../hmis-warehouse/docs/traefik/tools/traefik/config.sample.yml tools/traefik/config.yml

# Navigate to certs directory
cd tools/certs

# Create OpenSSL configuration file
cat > openssl.cnf <<-EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = *.$DOMAIN
[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.$DOMAIN
DNS.2 = $DOMAIN
DNS.3 = *.hmis-warehouse.$DOMAIN
EOF

# Generate SSL certificate
echo "Generating SSL certificate..."
openssl req \
  -new \
  -newkey rsa:2048 \
  -sha256 \
  -days 3650 \
  -nodes \
  -x509 \
  -keyout "$DOMAIN.key" \
  -out "$DOMAIN.crt" \
  -config openssl.cnf

# Clean up configuration file
rm openssl.cnf

# Add certificate to system keychain
echo "Adding certificate to system keychain..."
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$DOMAIN.crt"

echo "Done! SSL certificate for $DOMAIN has been generated and added to the system keychain."
echo "Certificate files:"
echo "  - Private key: $PWD/$DOMAIN.key"
echo "  - Certificate: $PWD/$DOMAIN.crt"
