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
    echo "  -d, --domain DOMAIN         Domain to clean up (default: dev.test)"
    echo "  -t, --traefik-path PATH     Path where traefik was installed"
    echo "  -m, --mailhog-path PATH     Path where mailhog was installed"
    echo "  --remove-packages           Also remove homebrew packages (colima, docker, etc.)"
    echo "  --keep-docker-network       Keep the development docker network"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --domain example.local --traefik-path ~/Sites/traefik --mailhog-path ~/Sites/mailhog"
    echo ""
    echo "This script will:"
    echo "  1. Stop and remove Docker services"
    echo "  2. Clean up DNS configuration"
    echo "  3. Remove SSL certificates from keychain"
    echo "  4. Clean up installation directories"
    echo "  5. Optionally remove homebrew packages"
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to ask for confirmation
confirm_step() {
    local step_name="$1"
    local step_description="$2"

    echo -e "${YELLOW}$step_name${NC}"
    echo "$step_description"
    echo ""
    read -p "Do you want to proceed with this step? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0  # Yes, proceed
    else
        echo -e "${BLUE}  Skipping $step_name${NC}"
        return 1  # No, skip
    fi
}

# Parse command line arguments
DOMAIN=""
TRAEFIK_PATH=""
MAILHOG_PATH=""
REMOVE_PACKAGES=false
KEEP_DOCKER_NETWORK=false

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
        --remove-packages)
            REMOVE_PACKAGES=true
            shift
            ;;
        --keep-docker-network)
            KEEP_DOCKER_NETWORK=true
            shift
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
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${RED}🗑️  HMIS Warehouse Developer Uninstallation${NC}"
echo "============================================="
echo ""

# Collect required information if not provided via arguments
if [ -z "$DOMAIN" ]; then
    echo -e "${YELLOW}Domain Configuration:${NC}"
    DOMAIN=$(prompt_with_default "Enter the domain that was used for installation" "dev.test")
fi

if [ -z "$TRAEFIK_PATH" ]; then
    echo -e "${YELLOW}Traefik Configuration:${NC}"
    DEFAULT_TRAEFIK="$HOME/Sites/traefik"
    TRAEFIK_PATH=$(prompt_with_default "Enter the path where traefik was installed" "$DEFAULT_TRAEFIK")
    TRAEFIK_PATH=$(expand_path "$TRAEFIK_PATH")
fi

if [ -z "$MAILHOG_PATH" ]; then
    echo -e "${YELLOW}MailHog Configuration:${NC}"
    DEFAULT_MAILHOG="$HOME/Sites/mailhog"
    MAILHOG_PATH=$(prompt_with_default "Enter the path where mailhog was installed" "$DEFAULT_MAILHOG")
    MAILHOG_PATH=$(expand_path "$MAILHOG_PATH")
fi

echo ""
echo -e "${BLUE}Uninstallation Summary:${NC}"
echo "  Domain: $DOMAIN"
echo "  Traefik path: $TRAEFIK_PATH"
echo "  MailHog path: $MAILHOG_PATH"
echo "  Remove packages: $REMOVE_PACKAGES"
echo "  Keep docker network: $KEEP_DOCKER_NETWORK"
echo ""

# Warning and confirmation
echo -e "${RED}⚠️  WARNING: This will remove all HMIS Warehouse development setup!${NC}"
echo ""
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 1
fi

echo ""
echo -e "${YELLOW}⚡ Requesting sudo access for system changes...${NC}"
# Cache sudo credentials upfront
sudo -v

echo ""
if confirm_step "Step 1/5: Stop and remove Docker services" "This will stop Colima, all running Docker containers (HMIS Warehouse, Traefik, MailHog) and optionally remove the development network."; then
    echo -e "${GREEN}Stopping and removing Docker services...${NC}"

    # Stop warehouse services
    echo "Stopping HMIS Warehouse services..."
    cd "$PROJECT_ROOT"
    docker-compose down 2>/dev/null || echo "  No warehouse services running"

    # Stop and remove traefik
    if [ -d "$TRAEFIK_PATH/traefik" ]; then
        echo "Stopping Traefik..."
        cd "$TRAEFIK_PATH/traefik"
        docker compose down 2>/dev/null || echo "  Traefik not running"
    else
        echo "  Traefik directory not found at $TRAEFIK_PATH/traefik"
    fi

    # Stop and remove mailhog
    if [ -d "$MAILHOG_PATH" ]; then
        echo "Stopping MailHog..."
        cd "$MAILHOG_PATH"
        docker compose down 2>/dev/null || echo "  MailHog not running"
    else
        echo "  MailHog directory not found at $MAILHOG_PATH"
    fi

    # Stop colima (this will stop the Docker daemon)
    if command_exists colima; then
        if colima status >/dev/null 2>&1; then
            echo "Stopping Colima..."
            colima stop || echo "  Failed to stop Colima"
        else
            echo "  Colima not running"
        fi
    else
        echo "  Colima not installed"
    fi

    # Remove docker network (only if colima is stopped and we're not keeping it)
    if [ "$KEEP_DOCKER_NETWORK" = false ]; then
        echo "Removing development docker network..."
        docker network rm development 2>/dev/null || echo "  Development network not found or Docker daemon not running"
    else
        echo "  Keeping development docker network as requested"
    fi
    echo -e "${GREEN}  ✅ Docker services cleanup complete${NC}"
fi

echo ""
if confirm_step "Step 2/5: Clean up DNS configuration" "This will stop dnsmasq, remove DNS configuration for *.$DOMAIN, remove the system resolver, and clean up /etc/hosts entries."; then
    echo -e "${GREEN}Cleaning up DNS configuration...${NC}"

    # Stop dnsmasq service
    if command_exists brew; then
        if brew services list | grep dnsmasq | grep -q started; then
            echo "Stopping dnsmasq service..."
            sudo brew services stop dnsmasq
        else
            echo "  dnsmasq service not running"
        fi
    else
        echo "  Homebrew not available, skipping dnsmasq service stop"
    fi

    # Remove dnsmasq configuration
    if command_exists brew; then
        DNSMASQ_CONF="$(brew --prefix)/etc/dnsmasq.conf"
        DNSMASQ_ADDRESS_LINE="address=/.$DOMAIN/127.0.0.1"

        if [ -f "$DNSMASQ_CONF" ]; then
            # Check if our specific domain configuration exists
            if grep -q "^$DNSMASQ_ADDRESS_LINE" "$DNSMASQ_CONF"; then
                echo "Removing dnsmasq configuration for $DOMAIN..."
                # Use grep -v to remove the line instead of sed with regex
                sudo grep -v "^$DNSMASQ_ADDRESS_LINE$" "$DNSMASQ_CONF" > "/tmp/dnsmasq.conf.tmp" && sudo mv "/tmp/dnsmasq.conf.tmp" "$DNSMASQ_CONF"
            fi

            # Check if the config file is now empty or only contains comments/whitespace
            if [ ! -s "$DNSMASQ_CONF" ] || ! grep -q "^[^#]" "$DNSMASQ_CONF" 2>/dev/null; then
                echo "Removing empty dnsmasq configuration file..."
                sudo rm "$DNSMASQ_CONF"
            fi
        fi
    fi

    # Remove system resolver
    RESOLVER_FILE="/etc/resolver/$DOMAIN"
    if [ -f "$RESOLVER_FILE" ]; then
        echo "Removing system resolver for $DOMAIN..."
        sudo rm "$RESOLVER_FILE"
    fi

    # Clean up /etc/hosts entries
    echo "Cleaning up /etc/hosts entries..."
    sudo sed -i '' '/# HMIS Warehouse/d' /etc/hosts 2>/dev/null || true
    sudo sed -i '' '/host\.docker\.internal.*Docker internal network access/d' /etc/hosts 2>/dev/null || true
    echo -e "${GREEN}  ✅ DNS configuration cleanup complete${NC}"
fi

echo ""
if confirm_step "Step 3/5: Remove SSL certificates" "This will remove the SSL certificate for *.$DOMAIN from the macOS System Keychain."; then
    echo -e "${GREEN}Removing SSL certificates...${NC}"

    # Remove certificate from system keychain
    CERT_PATH="$TRAEFIK_PATH/traefik/tools/certs/$DOMAIN.crt"
    if [ -f "$CERT_PATH" ]; then
        echo "Removing SSL certificate from system keychain..."
        # Find and remove the certificate from keychain
        CERT_SHA1=$(openssl x509 -noout -fingerprint -sha1 -inform pem -in "$CERT_PATH" 2>/dev/null | cut -d= -f2 | tr -d ':' || echo "")
        if [ -n "$CERT_SHA1" ]; then
            sudo security delete-certificate -Z "$CERT_SHA1" /Library/Keychains/System.keychain 2>/dev/null || echo "  Certificate not found in keychain or already removed"
        fi
    else
        echo "  Certificate file not found at $CERT_PATH"
    fi
    echo -e "${GREEN}  ✅ SSL certificate removal complete${NC}"
fi

echo ""
if confirm_step "Step 4/5: Clean up installation directories" "This will remove the Traefik directory ($TRAEFIK_PATH), MailHog directory ($MAILHOG_PATH), and warehouse environment files (.env.development.local, .env.local)."; then
    echo -e "${GREEN}Cleaning up installation directories...${NC}"

    # Clean up traefik directory
    if [ -d "$TRAEFIK_PATH" ]; then
        echo "Removing Traefik installation directory..."
        rm -rf "$TRAEFIK_PATH"
        echo "  Removed $TRAEFIK_PATH"
    else
        echo "  Traefik directory not found"
    fi

    # Clean up mailhog directory
    if [ -d "$MAILHOG_PATH" ]; then
        echo "Removing MailHog installation directory..."
        rm -rf "$MAILHOG_PATH"
        echo "  Removed $MAILHOG_PATH"
    else
        echo "  MailHog directory not found"
    fi

    # Clean up warehouse environment files
    cd "$PROJECT_ROOT"
    if [ -f ".env.development.local" ]; then
        echo "Removing warehouse environment files..."
        rm -f .env.development.local
        echo "  Removed .env.development.local"
    fi

    if [ -f ".env.local" ]; then
        rm -f .env.local
        echo "  Removed .env.local"
    fi
    echo -e "${GREEN}  ✅ Installation directories cleanup complete${NC}"
fi

echo ""
if [ "$REMOVE_PACKAGES" = true ]; then
    if confirm_step "Step 5/5: Remove homebrew packages" "This will remove homebrew packages (dnsmasq, colima, lima, docker, docker-compose), clean up Docker configuration, and remove CLI plugin symlinks."; then
        echo -e "${GREEN}Removing homebrew packages and configuration...${NC}"

        # Only remove packages if they were likely installed by our setup
        PACKAGES_TO_REMOVE=()

        if command_exists brew; then
            # Check each package and add to removal list
            for package in dnsmasq colima lima docker docker-compose; do
                if brew list "$package" >/dev/null 2>&1; then
                    PACKAGES_TO_REMOVE+=("$package")
                fi
            done

            if [ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]; then
                echo "  Removing packages: ${PACKAGES_TO_REMOVE[*]}"
                brew uninstall "${PACKAGES_TO_REMOVE[@]}" 2>/dev/null || echo "  Some packages may have dependencies preventing removal"
            else
                echo "  No packages to remove"
            fi
        fi

        # Clean up Docker configuration
        if [ -f "$HOME/.docker/config.json" ]; then
            echo "Cleaning up Docker configuration..."
            if grep -q "cliPluginsExtraDirs" "$HOME/.docker/config.json"; then
                # Remove the cliPluginsExtraDirs configuration
                if command_exists jq; then
                    jq 'del(.cliPluginsExtraDirs)' "$HOME/.docker/config.json" > "$HOME/.docker/config.json.tmp" && mv "$HOME/.docker/config.json.tmp" "$HOME/.docker/config.json"
                else
                    # Fallback: just remove the file if it only contains our config
                    if [ "$(cat "$HOME/.docker/config.json" | jq -r 'keys[]' 2>/dev/null)" = "cliPluginsExtraDirs" ]; then
                        rm "$HOME/.docker/config.json"
                    fi
                fi
            fi
        fi

        # Remove docker-compose symlink
        if [ -L "$HOME/.docker/cli-plugins/docker-compose" ]; then
            echo "Removing docker-compose CLI plugin symlink..."
            rm "$HOME/.docker/cli-plugins/docker-compose"
        fi
        echo -e "${GREEN}  ✅ Package cleanup complete${NC}"
    fi
else
    echo -e "${BLUE}Skipping package removal (use --remove-packages to remove homebrew packages)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Uninstallation Process Complete!${NC}"
echo "======================================="
echo ""
echo -e "${BLUE}HMIS Warehouse development environment uninstall process finished.${NC}"
echo ""
echo -e "${YELLOW}Note: Only the steps you confirmed were executed.${NC}"
echo "If you skipped any steps, those components remain installed."
echo ""

# Run system check to verify clean state
echo -e "${YELLOW}🔍 Verifying system is ready for reinstallation...${NC}"
echo ""

# Get script directory to find system_check.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_CHECK_SCRIPT="$SCRIPT_DIR/system_check.sh"

if [ -f "$SYSTEM_CHECK_SCRIPT" ]; then
    if "$SYSTEM_CHECK_SCRIPT" --quiet; then
        echo -e "${GREEN}✅ System check passed! Ready for clean reinstallation.${NC}"
        echo ""
        echo -e "${BLUE}To reinstall, run:${NC}"
        echo "  $SCRIPT_DIR/install.sh"
    else
        system_check_exit_code=$?
        if [ $system_check_exit_code -eq 2 ]; then
            echo -e "${YELLOW}⚠️  System check passed with warnings.${NC}"
            echo -e "${BLUE}Installation can proceed, but review any warnings above.${NC}"
            echo ""
            echo -e "${BLUE}To reinstall, run:${NC}"
            echo "  $SCRIPT_DIR/install.sh"
        else
            echo -e "${RED}❌ System check failed. Some cleanup may be incomplete.${NC}"
            echo -e "${YELLOW}Please resolve the issues above before attempting reinstallation.${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  System check script not found. Cannot verify clean state.${NC}"
fi

echo ""
echo -e "${YELLOW}Manual cleanup (if needed):${NC}"
echo "  • Flush DNS cache: sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
echo "  • Remove any remaining docker images: docker system prune -a"
echo "  • Check for any remaining certificates in Keychain Access.app"
echo "  • To run this script again with different options: $0 --help"
