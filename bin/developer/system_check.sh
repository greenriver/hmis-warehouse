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
    echo "  --quiet                     Only show errors and warnings"
    echo "  --check-ports PORTS         Check specific ports (comma-separated)"
    echo "  --min-memory GB             Minimum memory requirement in GB (default: 8)"
    echo "  --min-disk GB               Minimum disk space requirement in GB (default: 10)"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Example:"
    echo "  $0                          # Full system check"
    echo "  $0 --quiet                  # Only show issues"
    echo "  $0 --check-ports 80,443     # Check specific ports only"
    echo ""
    echo "Exit codes:"
    echo "  0: All checks passed"
    echo "  1: Critical issues found (installation should not proceed)"
    echo "  2: Warnings only (installation can proceed with caution)"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    local port="$1"
    lsof -i ":$port" >/dev/null 2>&1
}

# Function to get available memory in GB
get_memory_gb() {
    local memory_bytes
    memory_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    echo $((memory_bytes / 1024 / 1024 / 1024))
}

# Function to get available disk space in GB
get_disk_space_gb() {
    local available_kb
    available_kb=$(df -k "$HOME" | awk 'NR==2 {print $4}')
    echo $((available_kb / 1024 / 1024))
}

# Function to validate system requirements
validate_environment() {
    local quiet_mode="$1"
    local ports_to_check="$2"
    local min_memory="$3"
    local min_disk="$4"

    if [ "$quiet_mode" != "true" ]; then
        echo -e "${BLUE}🔍 Validating system environment...${NC}"
    fi

    local validation_failed=false
    local has_warnings=false

    # Check operating system
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}❌ Error: This installation script is designed for macOS only${NC}"
        echo "   Current OS: $OSTYPE"
        validation_failed=true
    else
        if [ "$quiet_mode" != "true" ]; then
            echo -e "${GREEN}✅ Operating System: macOS${NC}"
        fi
    fi

    # Check system requirements
    local memory_gb
    memory_gb=$(get_memory_gb)
    if [ "$memory_gb" -lt "$min_memory" ]; then
        echo -e "${RED}❌ Error: Insufficient memory${NC}"
        echo "   Required: ${min_memory}GB+ RAM"
        echo "   Available: ${memory_gb}GB RAM"
        echo "   Note: The warehouse requires significant memory for Docker containers"
        validation_failed=true
    else
        if [ "$quiet_mode" != "true" ]; then
            echo -e "${GREEN}✅ Memory: ${memory_gb}GB RAM available${NC}"
        fi
    fi

    local disk_space_gb
    disk_space_gb=$(get_disk_space_gb)
    if [ "$disk_space_gb" -lt "$min_disk" ]; then
        echo -e "${YELLOW}⚠️  Warning: Low disk space${NC}"
        echo "   Recommended: ${min_disk}GB+ free space"
        echo "   Available: ${disk_space_gb}GB free space"
        echo "   Docker images and data will require significant disk space"
        has_warnings=true
    else
        if [ "$quiet_mode" != "true" ]; then
            echo -e "${GREEN}✅ Disk Space: ${disk_space_gb}GB available${NC}"
        fi
    fi

    # Check for conflicting services on required ports
    IFS=',' read -ra PORTS <<< "$ports_to_check"
    local conflicting_ports=()

    for port in "${PORTS[@]}"; do
        if port_in_use "$port"; then
            conflicting_ports+=("$port")
        fi
    done

    if [ ${#conflicting_ports[@]} -gt 0 ]; then
        echo -e "${RED}❌ Error: Required ports are already in use${NC}"
        echo "   Conflicting ports: ${conflicting_ports[*]}"
        echo "   Port usage:"
        for port in "${conflicting_ports[@]}"; do
            echo "     Port $port: $(lsof -i ":$port" | head -2 | tail -1 | awk '{print $1, $2}')"
        done
        echo ""
        echo "   Required ports:"
        echo "     80, 443: Traefik reverse proxy"
        echo "     1025: MailHog SMTP"
        echo "     8025: MailHog web interface"
        echo "     8080: Traefik dashboard"
        echo ""
        echo "   Please stop conflicting services before proceeding."
        validation_failed=true
    else
        if [ "$quiet_mode" != "true" ]; then
            echo -e "${GREEN}✅ Required ports (${ports_to_check// /}) are available${NC}"
        fi
    fi

    # Check for existing conflicting installations
    # Check for existing dnsmasq configuration
    if command_exists brew; then
        local dnsmasq_conf="$(brew --prefix)/etc/dnsmasq.conf"
        if [ -f "$dnsmasq_conf" ] && grep -q "address=/" "$dnsmasq_conf"; then
            echo -e "${YELLOW}⚠️  Warning: Existing dnsmasq configuration found${NC}"
            echo "   File: $dnsmasq_conf"
            echo "   Existing wildcard DNS rules may conflict with installation"
            has_warnings=true
        fi
    fi

    # Check for existing Docker Desktop vs Colima conflict
    if [ -d "/Applications/Docker.app" ] && command_exists colima; then
        echo -e "${YELLOW}⚠️  Warning: Both Docker Desktop and Colima detected${NC}"
        echo "   This may cause conflicts. Consider using only one Docker solution."
        has_warnings=true
    fi

    # Check for existing traefik processes
    if pgrep -f "traefik" >/dev/null; then
        echo -e "${YELLOW}⚠️  Warning: Traefik process already running${NC}"
        echo "   This may conflict with the traefik installation"
        echo "   Consider stopping existing traefik before proceeding"
        has_warnings=true
    fi

    # Check write permissions for installation paths
    local test_paths=("$HOME/Sites" "/etc/resolver")
    for path in "${test_paths[@]}"; do
        if [ "$path" = "/etc/resolver" ]; then
            # Check if we can create the resolver directory with sudo
            if ! sudo -n test -w "/etc" 2>/dev/null; then
                if [ "$quiet_mode" != "true" ]; then
                    echo -e "${YELLOW}⚠️  Note: Will need sudo access to create $path${NC}"
                fi
            fi
        else
            # Check if we can write to the path
            if [ ! -d "$path" ]; then
                if ! mkdir -p "$path" 2>/dev/null; then
                    echo -e "${RED}❌ Error: Cannot create directory $path${NC}"
                    echo "   Please ensure you have write permissions"
                    validation_failed=true
                else
                    if [ "$quiet_mode" != "true" ]; then
                        echo -e "${GREEN}✅ Can create installation directory: $path${NC}"
                    fi
                    rmdir "$path" 2>/dev/null || true  # Clean up test directory if empty
                fi
            else
                if [ "$quiet_mode" != "true" ]; then
                    echo -e "${GREEN}✅ Installation directory exists: $path${NC}"
                fi
            fi
        fi
    done

    # Check for Xcode Command Line Tools (required for some homebrew packages)
    if ! xcode-select -p >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: Xcode Command Line Tools not installed${NC}"
        echo "   Install with: xcode-select --install"
        validation_failed=true
    else
        if [ "$quiet_mode" != "true" ]; then
            echo -e "${GREEN}✅ Xcode Command Line Tools installed${NC}"
        fi
    fi

    # Summary
    if [ "$quiet_mode" != "true" ]; then
        echo ""
    fi

    if [ "$validation_failed" = true ]; then
        echo -e "${RED}❌ Environment validation failed!${NC}"
        echo ""
        echo -e "${YELLOW}Please resolve the above issues before running the installation.${NC}"
        return 1
    elif [ "$has_warnings" = true ]; then
        if [ "$quiet_mode" != "true" ]; then
            echo -e "${YELLOW}⚠️  Environment validation passed with warnings${NC}"
            echo -e "${BLUE}Installation can proceed, but please review the warnings above.${NC}"
        fi
        return 2
    else
        if [ "$quiet_mode" != "true" ]; then
            echo -e "${GREEN}✅ Environment validation passed!${NC}"
            echo -e "${BLUE}Your system is ready for HMIS Warehouse installation.${NC}"
        fi
        return 0
    fi
}

# Parse command line arguments
QUIET_MODE=false
PORTS_TO_CHECK="80,443,1025,8025,8080"
MIN_MEMORY=8
MIN_DISK=10

while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet)
            QUIET_MODE=true
            shift
            ;;
        --check-ports)
            PORTS_TO_CHECK="$2"
            shift 2
            ;;
        --min-memory)
            MIN_MEMORY="$2"
            shift 2
            ;;
        --min-disk)
            MIN_DISK="$2"
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

# Run validation
validate_environment "$QUIET_MODE" "$PORTS_TO_CHECK" "$MIN_MEMORY" "$MIN_DISK"
exit_code=$?

# Show common solutions if there were failures
if [ $exit_code -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}Common solutions:${NC}"
    echo "• Install Xcode Command Line Tools: xcode-select --install"
    echo "• Free up disk space and ensure ${MIN_MEMORY}GB+ RAM"
    echo "• Stop conflicting services on required ports"
    echo "• Resolve Docker Desktop/Colima conflicts"
    echo ""
fi

exit $exit_code
