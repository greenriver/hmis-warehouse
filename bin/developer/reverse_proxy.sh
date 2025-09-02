#!/bin/bash

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 <traefik-installation-path> [domain]"
    echo "Example: $0 /Users/$(whoami)/traefik dev.test"
    echo ""
    echo "This script will:"
    echo "  1. Create traefik directory structure at the specified path"
    echo "  2. Copy traefik configuration files"
    echo "  3. Generate SSL certificates"
    echo "  4. Create a docker network and start traefik"
    exit 1
}

# Check if path argument is provided
if [ $# -lt 1 ]; then
    echo "Error: Please provide the traefik installation path"
    usage
fi

TRAEFIK_PATH="$1"
DOMAIN="${2:-dev.test}"  # Default to dev.test if not provided
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HMIS_WAREHOUSE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Setting up Traefik reverse proxy..."
echo "Installation path: $TRAEFIK_PATH"
echo "Domain: $DOMAIN"
echo "HMIS Warehouse root: $HMIS_WAREHOUSE_ROOT"

# Create traefik directory structure
echo "Creating directory structure..."
mkdir -p "$TRAEFIK_PATH"
cd "$TRAEFIK_PATH"
mkdir -p traefik/tools/certs
mkdir -p traefik/tools/traefik

# Copy and configure traefik configuration files
echo "Copying and configuring traefik files..."

# Copy sample files to destination
cp "$HMIS_WAREHOUSE_ROOT/docs/traefik/docker-compose.sample.yml" traefik/docker-compose.yml
cp "$HMIS_WAREHOUSE_ROOT/docs/traefik/tools/traefik/config.sample.yml" traefik/tools/traefik/config.yml

# Adjust config.yml if domain is not the default
if [ "$DOMAIN" != "dev.test" ]; then
    echo "Adjusting configuration for domain: $DOMAIN"
    sed -i '' "s/dev\.test/$DOMAIN/g" traefik/tools/traefik/config.yml
fi

# Generate certificates using the existing certificates.sh script
echo "Generating SSL certificates..."
"$SCRIPT_DIR/certificates.sh" "$DOMAIN" "$TRAEFIK_PATH"

# Navigate back to traefik directory
cd "$TRAEFIK_PATH/traefik"

# Create docker network if it doesn't exist
echo "Creating development docker network..."
if ! docker network ls | grep -q "development"; then
    docker network create development
    echo "Development network created ✓"
else
    echo "Development network already exists ✓"
fi

# Start traefik
echo "Starting Traefik reverse proxy..."
docker compose up -d reverse-proxy

echo ""
echo "Traefik reverse proxy setup complete! 🎉"
echo ""
echo "Configuration details:"
echo "  - Installation path: $TRAEFIK_PATH/traefik"
echo "  - Domain: $DOMAIN"
echo "  - Certificate files:"
echo "    - Private key: $TRAEFIK_PATH/traefik/tools/certs/$DOMAIN.key"
echo "    - Certificate: $TRAEFIK_PATH/traefik/tools/certs/$DOMAIN.crt"
echo "  - Traefik dashboard: http://localhost:8080"
echo "  - Docker network: development"
echo ""
echo "To stop Traefik: cd $TRAEFIK_PATH/traefik && docker compose down"
echo "To restart Traefik: cd $TRAEFIK_PATH/traefik && docker compose up -d"
