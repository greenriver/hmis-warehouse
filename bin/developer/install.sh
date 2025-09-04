#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --domain DOMAIN         Domain to use (default: dev.test)"
    echo "  -t, --traefik-path PATH     Path for traefik installation"
    echo "  -m, --mailhog-path PATH     Path for mailhog installation"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --domain example.local --traefik-path ~/Sites/traefik --mailhog-path ~/Sites/mailhog"
    echo ""
    echo "This script will:"
    echo "  1. Install prerequisites (homebrew, docker, etc.)"
    echo "  2. Setup DNS resolution"
    echo "  3. Setup reverse proxy (traefik) and generate certificates"
    echo "  4. Setup mail service (mailhog)"
    echo "  5. Setup the HMIS Warehouse application"
    exit 1
}

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -p "$prompt: " result
        echo "$result"
    fi
}

# Function to expand tilde in paths
expand_path() {
    echo "${1/#\~/$HOME}"
}





# Parse command line arguments
DOMAIN=""
TRAEFIK_PATH=""
MAILHOG_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -t|--traefik-path)
            TRAEFIK_PATH="$2"
            shift 2
            ;;
        -m|--mailhog-path)
            MAILHOG_PATH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 HMIS Warehouse Developer Installation${NC}"
echo "========================================"
echo ""

# Validate system environment before proceeding
if ! "$SCRIPT_DIR/system_check.sh"; then
    echo ""
    echo -e "${RED}Installation aborted due to validation failures.${NC}"
    exit 1
fi

echo ""

# Collect required information if not provided via arguments
if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}Domain Configuration:${NC}"
    DOMAIN=$(prompt_with_default "Enter the domain to use for development" "dev.test")
fi

if [ -z "$TRAEFIK_PATH" ]; then
    echo -e "${YELLOW}Traefik Configuration:${NC}"
    DEFAULT_TRAEFIK="$HOME/Sites/traefik"
    TRAEFIK_PATH=$(prompt_with_default "Enter the path for traefik installation" "$DEFAULT_TRAEFIK")
    TRAEFIK_PATH=$(expand_path "$TRAEFIK_PATH")
fi

if [ -z "$MAILHOG_PATH" ]; then
    echo -e "${YELLOW}MailHog Configuration:${NC}"
    DEFAULT_MAILHOG="$HOME/Sites/mailhog"
    MAILHOG_PATH=$(prompt_with_default "Enter the path for mailhog installation" "$DEFAULT_MAILHOG")
    MAILHOG_PATH=$(expand_path "$MAILHOG_PATH")
fi

echo ""
echo -e "${BLUE}Installation Summary:${NC}"
echo "  Domain: $DOMAIN"
echo "  Traefik path: $TRAEFIK_PATH"
echo "  MailHog path: $MAILHOG_PATH"
echo ""

# Confirm installation
read -p "Proceed with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi



echo ""
echo -e "${GREEN}Step 1/5: Installing prerequisites...${NC}"
"$SCRIPT_DIR/prerequisites.sh"

# Reload shell environment to pick up all new tools
echo "Reloading shell environment..."

# Source common shell profile files to pick up any changes
(source ~/.zshrc 2>/dev/null) || true

# Ensure Homebrew is in PATH based on architecture
if [[ $(uname -m) == "arm64" ]]; then
    # Apple Silicon Mac - add Homebrew to PATH
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true
    fi
else
    # Intel Mac - add Homebrew to PATH
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    if [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || true
    fi
fi

# Verify key tools are now available
echo "Verifying tool availability..."
if command -v brew >/dev/null 2>&1; then
    echo "  ✓ brew available"
else
    echo "  ⚠️  brew not found in PATH"
fi

if command -v docker >/dev/null 2>&1; then
    echo "  ✓ docker available"
else
    echo "  ⚠️  docker not found in PATH"
fi

if command -v colima >/dev/null 2>&1; then
    echo "  ✓ colima available"
else
    echo "  ⚠️  colima not found in PATH"
fi

# Start colima if it was installed and isn't running
if command -v colima >/dev/null 2>&1; then
    if ! colima status >/dev/null 2>&1; then
        echo "Starting colima..."
        colima start
        echo "Colima started ✓"
    else
        echo "Colima already running ✓"
    fi
fi

echo ""
echo -e "${GREEN}Step 2/5: Setting up DNS resolution...${NC}"
"$SCRIPT_DIR/dns.sh" "$DOMAIN"

echo ""
echo -e "${GREEN}Step 3/5: Setting up reverse proxy and certificates...${NC}"
"$SCRIPT_DIR/reverse_proxy.sh" "$TRAEFIK_PATH" "$DOMAIN"

echo ""
echo -e "${GREEN}Step 4/5: Setting up mail service...${NC}"
"$SCRIPT_DIR/mail.sh" "$MAILHOG_PATH" "$DOMAIN"

echo ""
echo -e "${GREEN}Step 5/5: Setting up HMIS Warehouse...${NC}"
"$SCRIPT_DIR/warehouse.sh" "$DOMAIN"

echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "=========================="
echo ""
echo -e "${BLUE}Your HMIS Warehouse development environment is ready!${NC}"
echo ""
echo "🌐 Services:"
echo "  • HMIS Warehouse: https://hmis-warehouse.$DOMAIN"
echo "  • MailHog (Mail): https://mailhog.$DOMAIN"
echo "  • Traefik Dashboard: http://localhost:8080"
echo ""
echo "🚀 To start the web container:"
echo "  cd $(dirname "$SCRIPT_DIR")"
echo "  docker-compose run --rm web"
echo ""
echo "🚀 To start the full warehouse stack:"
echo "  docker-compose up -d"

echo ""
echo "📁 Installation paths:"
echo "  • Traefik: $TRAEFIK_PATH"
echo "  • MailHog: $MAILHOG_PATH"
echo ""
echo "🔧 Useful commands:"
echo "  • View application logs: docker-compose logs -f web"
echo "  • Stop all services: docker-compose down"
echo "  • Restart traefik: cd $TRAEFIK_PATH/traefik && docker compose restart"
echo "  • Restart mailhog: cd $MAILHOG_PATH && docker compose restart"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  1. Reload your shell environment to activate direnv:"
echo "     source ~/.zshrc  # (or restart your terminal)"
echo "  2. Start the application with the command above"
echo "  3. Visit https://hmis-warehouse.$DOMAIN to access the application"
echo "  4. Check https://mailhog.$DOMAIN to see development emails"
echo ""
echo -e "${BLUE}Note:${NC} Environment variables are now managed via .envrc (using direnv)"
echo "Edit .envrc in the warehouse directory to customize your development environment."
