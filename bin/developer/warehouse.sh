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

# Get the project root directory (two levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Setting up HMIS Warehouse for domain: $DOMAIN"
echo "Project root: $PROJECT_ROOT"

# Change to project root directory
cd "$PROJECT_ROOT"

# Copy sample environment file
echo "Copying sample.env to .env.development.local..."
cp sample.env .env.development.local

# Create .env.local file
echo "Creating .env.local..."
touch .env.local

# Copy and configure .envrc file
echo "Setting up .envrc file..."
cp docs/sample_files/envrc.sample .envrc

# Update domain in .env.development.local if different from default
if [ "$DOMAIN" != "$DEFAULT_DOMAIN" ]; then
    echo "Updating domain from $DEFAULT_DOMAIN to $DOMAIN in .env.development.local..."
    sed -i '' "s/$DEFAULT_DOMAIN/$DOMAIN/g" .env.development.local
    echo "Domain updated in .env.development.local ✓"

    echo "Updating domain from $DEFAULT_DOMAIN to $DOMAIN in .envrc..."
    sed -i '' "s/$DEFAULT_DOMAIN/$DOMAIN/g" .envrc
    echo "Domain updated in .envrc ✓"
else
    echo "Using default domain ($DEFAULT_DOMAIN) ✓"
fi

# Configure direnv
echo "Configuring direnv..."
if command -v direnv >/dev/null 2>&1; then
    direnv allow .
    echo "direnv configured and allowed ✓"
else
    echo "⚠️  direnv not found in PATH. You may need to reload your shell or add direnv to your PATH."
    echo "   After direnv is available, run: direnv allow"
fi

# Fix initial permissions (only on directories that exist)
echo "Fixing initial permissions..."
docker compose run -u 0 shell chown -R app-user:app-user /bundle /app

# Run setup script
echo "Running application setup..."
docker compose run --rm shell bin/setup

# Fix permissions after setup (including node_modules which should now exist)
echo "Fixing final permissions..."
docker compose run -u 0 shell bash -c 'chown -R app-user:app-user /bundle /app && if [ -d /node_modules ]; then chown -R app-user:app-user /node_modules; fi'

echo ""
echo "Warehouse setup complete! 🎉"
echo ""
echo "Your application should now be available at:"
echo "  https://hmis-warehouse.$DOMAIN"
echo ""
echo "To start the application, run:"
echo "  docker compose run --rm web"
