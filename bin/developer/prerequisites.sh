#!/bin/bash

set -e  # Exit on any error

echo "Setting up HMIS Warehouse development prerequisites..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a brew package is installed
brew_package_installed() {
    brew list "$1" >/dev/null 2>&1
}

# Function to check if Docker Desktop is installed
docker_desktop_installed() {
    [ -d "/Applications/Docker.app" ] || [ -d "$HOME/Applications/Docker.app" ]
}

# 1. Install Homebrew if not installed
if ! command_exists brew; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed ✓"
fi

# 2. Install packages based on Docker Desktop presence
COLIMA_INSTALLED=false

if docker_desktop_installed; then
    echo "Docker Desktop detected. Installing only direnv..."
    if ! brew_package_installed direnv; then
        brew install direnv
        echo "direnv installed ✓"
    else
        echo "direnv already installed ✓"
    fi
else
    echo "Docker Desktop not detected. Installing lima, colima, docker, docker-compose, and direnv..."

    PACKAGES_TO_INSTALL=()

    if ! brew_package_installed lima; then
        PACKAGES_TO_INSTALL+=(lima)
    else
        echo "lima already installed ✓"
    fi

    if ! brew_package_installed colima; then
        PACKAGES_TO_INSTALL+=(colima)
        COLIMA_INSTALLED=true
    else
        echo "colima already installed ✓"
        COLIMA_INSTALLED=true
    fi

    if ! brew_package_installed docker; then
        PACKAGES_TO_INSTALL+=(docker)
    else
        echo "docker already installed ✓"
    fi

    if ! brew_package_installed docker-compose; then
        PACKAGES_TO_INSTALL+=(docker-compose)
    else
        echo "docker-compose already installed ✓"
    fi

    if ! brew_package_installed direnv; then
        PACKAGES_TO_INSTALL+=(direnv)
    else
        echo "direnv already installed ✓"
    fi

    if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
        echo "Installing: ${PACKAGES_TO_INSTALL[*]}"
        brew install "${PACKAGES_TO_INSTALL[@]}"
        echo "Packages installed ✓"
    fi
fi

# 3. Configure Docker CLI plugins if colima was installed
if [ "$COLIMA_INSTALLED" = true ]; then
    DOCKER_CONFIG_FILE="$HOME/.docker/config.json"

    # Create .docker directory if it doesn't exist
    mkdir -p "$HOME/.docker"

    # Create config.json if it doesn't exist
    if [ ! -f "$DOCKER_CONFIG_FILE" ]; then
        echo '{}' > "$DOCKER_CONFIG_FILE"
    fi

    # Check if cliPluginsExtraDirs already exists in config
    if ! grep -q "cliPluginsExtraDirs" "$DOCKER_CONFIG_FILE"; then
        echo "Adding cliPluginsExtraDirs to Docker config..."

        # Use jq if available, otherwise use a simple approach
        if command_exists jq; then
            jq '.cliPluginsExtraDirs = ["/opt/homebrew/lib/docker/cli-plugins"]' "$DOCKER_CONFIG_FILE" > "$DOCKER_CONFIG_FILE.tmp" && mv "$DOCKER_CONFIG_FILE.tmp" "$DOCKER_CONFIG_FILE"
        else
            # Fallback: create a new config file with the required setting
            cat > "$DOCKER_CONFIG_FILE" << 'EOF'
{
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
EOF
        fi
        echo "Docker config updated ✓"
    else
        echo "cliPluginsExtraDirs already configured in Docker config ✓"
    fi

    # Create CLI plugins directory and symlink
    mkdir -p ~/.docker/cli-plugins
    if [ ! -L ~/.docker/cli-plugins/docker-compose ]; then
        ln -sfn /opt/homebrew/bin/docker-compose ~/.docker/cli-plugins/docker-compose
        echo "Docker compose CLI plugin symlink created ✓"
    else
        echo "Docker compose CLI plugin symlink already exists ✓"
    fi
fi

# 4. Configure colima template if colima was installed
if [ "$COLIMA_INSTALLED" = true ]; then
    echo "Configuring colima..."

    # Stop colima if running to modify configuration
    if colima status >/dev/null 2>&1; then
        colima stop
    fi

    # Create colima configuration directory
    mkdir -p ~/.colima

    # Generate the base template non-interactively
    echo "Generating base colima configuration..."
    EDITOR=true colima template > ~/.colima/default.yaml

    # Update the template with our required values
    echo "Applying HMIS Warehouse optimizations..."
    sed -i '' 's/cpu: [0-9]*/cpu: 8/' ~/.colima/default.yaml
    sed -i '' 's/memory: [0-9]*/memory: 16/' ~/.colima/default.yaml
    sed -i '' 's/vmType: .*/vmType: vz/' ~/.colima/default.yaml
    sed -i '' 's/rosetta: .*/rosetta: true/' ~/.colima/default.yaml
    sed -i '' 's/mountType: .*/mountType: virtiofs/' ~/.colima/default.yaml

    # Add a comment at the top to indicate this is customized
    sed -i '' '1i\
# Colima configuration for HMIS Warehouse development\
# Base template generated by colima, customized for warehouse requirements\
' ~/.colima/default.yaml

    echo "Colima configuration created ✓"
    echo "Configuration file: ~/.colima/default.yaml"
    echo "Applied customizations:"
    echo "  - CPU: 8 cores"
    echo "  - Memory: 16GB"
    echo "  - VM Type: vz (Apple Virtualization)"
    echo "  - Rosetta: enabled"
    echo "  - Mount Type: virtiofs"
    echo ""
    echo "To start colima with this configuration:"
    echo "  colima start"
    echo "To start colima on boot:"
    echo "  brew services start colima"
fi

echo ""
echo "Prerequisites setup complete! 🎉"
