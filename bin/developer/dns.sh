#!/bin/bash

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 [domain]"
    echo "Example: $0 dev.test"
    echo ""
    echo "This script sets up dnsmasq to automatically resolve all subdomains"
    echo "of the specified domain (default: dev.test) to 127.0.0.1"
    echo ""
    echo "This eliminates the need to manually edit /etc/hosts for each subdomain."
    echo "After setup, any *.dev.test domain will automatically resolve to localhost."
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a brew package is installed
brew_package_installed() {
    brew list "$1" >/dev/null 2>&1 || return 1
}

DOMAIN="${1:-dev.test}"  # Default to dev.test if not provided
HOSTS_FILE="/etc/hosts"

echo "Setting up DNS resolution for *.$DOMAIN using dnsmasq..."
echo "Domain: $DOMAIN"

# Check if Homebrew is installed
if ! command_exists brew; then
    echo "Error: Homebrew is required but not installed."
    echo "Please install Homebrew first: https://brew.sh/"
    exit 1
fi

# Install dnsmasq if not already installed
if ! brew_package_installed dnsmasq; then
    echo "Installing dnsmasq..."
    brew install dnsmasq
    echo "dnsmasq installed ✓"
else
    echo "dnsmasq already installed ✓"
fi

# Configure dnsmasq
DNSMASQ_CONF="$(brew --prefix)/etc/dnsmasq.conf"
DNSMASQ_ADDRESS_LINE="address=/.$DOMAIN/127.0.0.1"

echo "Configuring dnsmasq..."
if ! grep -q "^$DNSMASQ_ADDRESS_LINE" "$DNSMASQ_CONF" 2>/dev/null; then
    echo "$DNSMASQ_ADDRESS_LINE" | sudo tee -a "$DNSMASQ_CONF" > /dev/null
    echo "Added wildcard DNS rule to dnsmasq.conf ✓"
else
    echo "dnsmasq wildcard rule already configured ✓"
fi

# Set up the resolver
RESOLVER_DIR="/etc/resolver"
RESOLVER_FILE="$RESOLVER_DIR/$DOMAIN"

echo "Setting up system resolver..."
sudo mkdir -p "$RESOLVER_DIR"

if [ ! -f "$RESOLVER_FILE" ] || ! grep -q "nameserver 127.0.0.1" "$RESOLVER_FILE" 2>/dev/null; then
    echo "nameserver 127.0.0.1" | sudo tee "$RESOLVER_FILE" > /dev/null
    echo "Created resolver configuration for .$DOMAIN ✓"
else
    echo "Resolver configuration already exists ✓"
fi

# Add host.docker.internal entry to /etc/hosts for Docker compatibility
echo "Adding Docker compatibility entry..."
DOCKER_ENTRY="127.0.0.1 host.docker.internal # Docker internal network access"

if ! grep -q "host.docker.internal" "$HOSTS_FILE" 2>/dev/null; then
    if ! grep -q "# HMIS Warehouse" "$HOSTS_FILE" 2>/dev/null; then
        echo "" | sudo tee -a "$HOSTS_FILE" > /dev/null
        echo "# HMIS Warehouse" | sudo tee -a "$HOSTS_FILE" > /dev/null
    fi
    echo "$DOCKER_ENTRY" | sudo tee -a "$HOSTS_FILE" > /dev/null
    echo "Added host.docker.internal entry ✓"
else
    echo "host.docker.internal entry already exists ✓"
fi

# Start/restart dnsmasq
echo "Starting dnsmasq service..."
if brew services list | grep dnsmasq | grep -q started; then
    sudo brew services restart dnsmasq
    echo "dnsmasq service restarted ✓"
else
    sudo brew services start dnsmasq
    echo "dnsmasq service started ✓"
fi

# Test the configuration
echo ""
echo "Testing DNS resolution..."
sleep 2  # Give dnsmasq a moment to start

if nslookup "test.$DOMAIN" 127.0.0.1 >/dev/null 2>&1; then
    echo "DNS resolution test successful ✓"
else
    echo "⚠️  DNS resolution test failed. You may need to flush your DNS cache:"
    echo "   sudo dscacheutil -flushcache"
    echo "   sudo killall -HUP mDNSResponder"
fi

echo ""
echo "DNS setup complete! 🎉"
echo ""
echo "Configuration details:"
echo "  - Domain: *.$DOMAIN"
echo "  - All subdomains of $DOMAIN now resolve to 127.0.0.1"
echo "  - dnsmasq config: $DNSMASQ_CONF"
echo "  - Resolver config: $RESOLVER_FILE"
echo "  - Service status: $(brew services list | grep dnsmasq | awk '{print $2}')"
echo ""
echo "Examples of domains that now work:"
echo "  - hmis-warehouse.$DOMAIN"
echo "  - mailhog.$DOMAIN"
echo "  - s3.$DOMAIN"
echo "  - any-subdomain.$DOMAIN"
echo ""
echo "To stop dnsmasq: sudo brew services stop dnsmasq"
echo "To restart dnsmasq: sudo brew services restart dnsmasq"
