#!/bin/bash
set -e

# Script to install multiple versions of pg_repack
# Define the versions to install here
VERSIONS=("1.5.1" "1.5.2")

TEMP_DIR="/tmp/pg_repack_build"
PG_CONFIG=$(which pg_config)

if [ -z "$PG_CONFIG" ]; then
    echo "Error: pg_config not found. PostgreSQL development packages must be installed."
    exit 1
fi

echo "Using PostgreSQL configuration from: $PG_CONFIG"
echo "PostgreSQL version: $($PG_CONFIG --version)"
echo "Installing pg_repack versions: ${VERSIONS[*]}"

# Create temporary build directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Install each defined version
for VERSION in "${VERSIONS[@]}"; do
    echo "Installing pg_repack version $VERSION..."
    
    # Download and extract
    curl -L -o "pg_repack-${VERSION}.zip" "https://api.pgxn.org/dist/pg_repack/${VERSION}/pg_repack-${VERSION}.zip"
    unzip "pg_repack-${VERSION}.zip"
    cd "pg_repack-${VERSION}"
    
    # Build and install with version-specific naming
    make PG_CONFIG="$PG_CONFIG"
    
    # Install with version suffix to avoid conflicts
    make install PG_CONFIG="$PG_CONFIG"
    
    # Create version-specific binary
    PG_BIN_DIR=$($PG_CONFIG --bindir)
    if [ -f "$PG_BIN_DIR/pg_repack" ]; then
        cp "$PG_BIN_DIR/pg_repack" "$PG_BIN_DIR/pg_repack-${VERSION}"
        echo "Created version-specific binary: $PG_BIN_DIR/pg_repack-${VERSION}"
    fi
    
    # Clean up this version's build files
    cd ..
    rm -rf "pg_repack-${VERSION}" "pg_repack-${VERSION}.zip"
    
    echo "Successfully installed pg_repack version $VERSION"
done

# Clean up temporary directory
cd /
rm -rf "$TEMP_DIR"

echo "All pg_repack versions installed successfully!"

# Verify installations by checking for the extension files and binaries
PG_LIB_DIR=$($PG_CONFIG --pkglibdir)
PG_SHARE_DIR=$($PG_CONFIG --sharedir)
PG_BIN_DIR=$($PG_CONFIG --bindir)

echo "PostgreSQL directories:"
echo "  Binaries: $PG_BIN_DIR"
echo "  Libraries: $PG_LIB_DIR"
echo "  Extensions: $PG_SHARE_DIR/extension"

echo ""
echo "Installed pg_repack files:"
echo "  Extension libraries:"
ls -la "$PG_LIB_DIR"/pg_repack* 2>/dev/null || echo "    No pg_repack library files found"

echo "  Extension control/sql files:"
ls -la "$PG_SHARE_DIR"/extension/pg_repack* 2>/dev/null || echo "    No pg_repack extension files found"

echo "  Binary executables:"
ls -la "$PG_BIN_DIR"/pg_repack* 2>/dev/null || echo "    No pg_repack binary files found"

# Check all available pg_repack binaries and their versions
echo ""
echo "Available pg_repack binaries:"
for binary in "$PG_BIN_DIR"/pg_repack*; do
    if [ -f "$binary" ] && [ -x "$binary" ]; then
        binary_name=$(basename "$binary")
        echo "  $binary_name: $($binary --version 2>/dev/null || echo 'version check failed')"
    fi
done

# Check if main pg_repack binary is in PATH
echo ""
echo "PATH check:"
if command -v pg_repack >/dev/null 2>&1; then
    echo "  pg_repack found in PATH: $(which pg_repack)"
    echo "  Default version: $(pg_repack --version 2>/dev/null || echo 'version check failed')"
else
    echo "  pg_repack NOT found in PATH"
    echo "  Current PATH: $PATH"
fi
