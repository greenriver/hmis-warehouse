#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 <domain> [output-directory]"
    echo ""
    echo "Arguments:"
    echo "  domain              Domain for the certificate (e.g., dev.test, example.local)"
    echo "  output-directory    Directory to save certificates (default: current directory)"
    echo ""
    echo "Examples:"
    echo "  $0 dev.test                           # Creates certificates in current directory"
    echo "  $0 example.local /path/to/certs       # Creates certificates in specified directory"
    echo ""
    echo "This script generates:"
    echo "  - A wildcard SSL certificate for *.<domain>"
    echo "  - Private key file: <domain>.key"
    echo "  - Certificate file: <domain>.crt"
    echo "  - Adds certificate to macOS System Keychain"
    exit 1
}

# Check if domain argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a domain"
    usage
fi

# Handle help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

DOMAIN="$1"
OUTPUT_DIR="${2:-.}"  # Default to current directory if not specified

echo "Generating SSL certificates for domain: $DOMAIN"
echo "Output directory: $OUTPUT_DIR"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

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
echo ""
echo "Certificate files created:"
echo "  - Private key: $PWD/$DOMAIN.key"
echo "  - Certificate: $PWD/$DOMAIN.crt"
echo ""
echo "The certificate covers:"
echo "  - *.$DOMAIN (wildcard)"
echo "  - $DOMAIN (base domain)"
echo "  - *.hmis-warehouse.$DOMAIN (warehouse subdomains)"
