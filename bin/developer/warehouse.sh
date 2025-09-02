#!/bin/bash

set -e  # Exit on any error

# Check if domain argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 example.local"
    exit 1
fi

DOMAIN="$1"
DEFAULT_DOMAIN="dev.test"

echo "Setting up HMIS Warehouse for domain: $DOMAIN"

# Copy sample environment file
echo "Copying sample.env to .env.development.local..."
cp sample.env .env.development.local

# Create .env.local file
echo "Creating .env.local..."
touch .env.local

# Update domain in .env.development.local if different from default
if [ "$DOMAIN" != "$DEFAULT_DOMAIN" ]; then
    echo "Updating domain from $DEFAULT_DOMAIN to $DOMAIN in .env.development.local..."
    sed -i '' "s/$DEFAULT_DOMAIN/$DOMAIN/g" .env.development.local
    echo "Domain updated ✓"
else
    echo "Using default domain ($DEFAULT_DOMAIN) ✓"
fi

# Fix permissions
echo "Fixing permissions..."
docker compose run -u 0 shell chown -R app-user:app-user /bundle /app /node_modules

# Run setup script
echo "Running application setup..."
docker-compose run --rm shell bin/setup

echo ""
echo "Warehouse setup complete! 🎉"
echo ""
echo "Your application should now be available at:"
echo "  https://hmis-warehouse.$DOMAIN"
echo ""
echo "To start the application, run:"
echo "  docker-compose run --rm web"
