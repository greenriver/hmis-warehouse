#!/bin/bash

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 <mailhog-installation-path> [domain]"
    echo "Example: $0 /Users/$(whoami)/Sites/mailhog dev.test"
    echo ""
    echo "This script will:"
    echo "  1. Create mailhog directory at the specified path"
    echo "  2. Copy and configure mailhog docker-compose.yml"
    echo "  3. Create docker network if needed"
    echo "  4. Start mailhog service"
    exit 1
}

# Check if path argument is provided
if [ $# -lt 1 ]; then
    echo "Error: Please provide the mailhog installation path"
    usage
fi

MAILHOG_PATH="$1"
DOMAIN="${2:-dev.test}"  # Default to dev.test if not provided
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HMIS_WAREHOUSE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Setting up MailHog mail service..."
echo "Installation path: $MAILHOG_PATH"
echo "Domain: $DOMAIN"

# Create mailhog directory
echo "Creating mailhog directory..."
mkdir -p "$MAILHOG_PATH"
cd "$MAILHOG_PATH"

# Copy and configure docker-compose file
echo "Copying and configuring mailhog docker-compose.yml..."
cp "$HMIS_WAREHOUSE_ROOT/docs/mailhog/docker-compose.sample.yml" docker-compose.yml

# Update domain if not default
if [ "$DOMAIN" != "dev.test" ]; then
    echo "Updating configuration for domain: $DOMAIN"
    sed -i '' "s/dev\.test/$DOMAIN/g" docker-compose.yml
    echo "Domain updated ✓"
else
    echo "Using default domain (dev.test) ✓"
fi

# Create docker network if it doesn't exist
echo "Ensuring development docker network exists..."
if ! docker network ls | grep -q "development"; then
    docker network create development
    echo "Development network created ✓"
else
    echo "Development network already exists ✓"
fi

# Start mailhog
echo "Starting MailHog service..."
docker compose up -d

echo ""
echo "MailHog setup complete! 🎉"
echo ""
echo "Configuration details:"
echo "  - Installation path: $MAILHOG_PATH"
echo "  - Domain: $DOMAIN"
echo "  - Web interface: https://mailhog.$DOMAIN"
echo "  - SMTP server: localhost:1025"
echo "  - Docker network: development"
echo ""
echo "To stop MailHog: cd $MAILHOG_PATH && docker compose down"
echo "To restart MailHog: cd $MAILHOG_PATH && docker compose up -d"
echo "To view logs: cd $MAILHOG_PATH && docker compose logs -f"
