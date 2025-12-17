#!/bin/bash
#
# siteblock installer
# Installs siteblock to /usr/local/bin
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/siteblock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Check for root
if [[ $EUID -ne 0 ]]; then
  print_error "This installer must be run as root (use sudo)"
  exit 1
fi

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║         siteblock installer           ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Create config directory
print_info "Creating config directory..."
mkdir -p "$CONFIG_DIR"

# Copy sites.txt to config directory if it doesn't exist
if [[ ! -f "$CONFIG_DIR/sites.txt" ]]; then
  cp "$SCRIPT_DIR/sites.txt" "$CONFIG_DIR/sites.txt"
  print_success "Copied sites.txt to $CONFIG_DIR/"
else
  print_info "sites.txt already exists in $CONFIG_DIR/, keeping existing file"
fi

# Create the wrapper script that points to the config directory
cat > "$INSTALL_DIR/siteblock" << 'SCRIPT'
#!/bin/bash
export SITEBLOCK_SITES_FILE="/etc/siteblock/sites.txt"
exec /usr/local/share/siteblock/siteblock.sh "$@"
SCRIPT

# Copy the main script
mkdir -p /usr/local/share/siteblock
cp "$SCRIPT_DIR/siteblock.sh" /usr/local/share/siteblock/siteblock.sh

# Set permissions
chmod +x "$INSTALL_DIR/siteblock"
chmod +x /usr/local/share/siteblock/siteblock.sh
chmod 644 "$CONFIG_DIR/sites.txt"

print_success "Installed siteblock to $INSTALL_DIR/siteblock"
print_success "Configuration file: $CONFIG_DIR/sites.txt"

echo ""
echo -e "${YELLOW}Quick Start:${NC}"
echo "  sudo siteblock block     # Block configured sites"
echo "  sudo siteblock unblock   # Unblock all sites"
echo "  siteblock status         # Check status"
echo "  siteblock help           # Show all commands"
echo ""
echo -e "${YELLOW}Edit blocked sites:${NC}"
echo "  sudo nano $CONFIG_DIR/sites.txt"
echo ""
print_success "Installation complete!"