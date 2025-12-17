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

REPO_URL="https://raw.githubusercontent.com/purushottamnawale/siteblock/main"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/siteblock"
SHARE_DIR="/usr/local/share/siteblock"

# Detect if running from a local directory or via curl/wget
if [[ -f "siteblock.sh" ]]; then
  SCRIPT_DIR="$(pwd)"
  IS_LOCAL=true
else
  SCRIPT_DIR="$(mktemp -d)"
  IS_LOCAL=false
fi

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

# Download files if not local
if [[ "$IS_LOCAL" == "false" ]]; then
  print_info "Downloading files from repository..."
  
  download_file() {
    local file="$1"
    local url="$REPO_URL/$file"
    if command -v curl &> /dev/null; then
      curl -fsSL "$url" -o "$SCRIPT_DIR/$file"
    elif command -v wget &> /dev/null; then
      wget -q "$url" -O "$SCRIPT_DIR/$file"
    else
      print_error "Neither curl nor wget found. Please install one of them."
      exit 1
    fi
  }

  download_file "siteblock.sh"
  download_file "sites.txt"
  download_file "uninstall.sh"
fi

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

# Create share directory
mkdir -p "$SHARE_DIR"

# Copy scripts
cp "$SCRIPT_DIR/siteblock.sh" "$SHARE_DIR/siteblock.sh"
cp "$SCRIPT_DIR/uninstall.sh" "$SHARE_DIR/uninstall.sh"

# Create the wrapper script
cat > "$INSTALL_DIR/siteblock" << 'SCRIPT'
#!/bin/bash
export SITEBLOCK_SITES_FILE="/etc/siteblock/sites.txt"
exec /usr/local/share/siteblock/siteblock.sh "$@"
SCRIPT

# Set permissions
chmod +x "$INSTALL_DIR/siteblock"
chmod +x "$SHARE_DIR/siteblock.sh"
chmod +x "$SHARE_DIR/uninstall.sh"
chmod 644 "$CONFIG_DIR/sites.txt"

# Cleanup temp dir if downloaded
if [[ "$IS_LOCAL" == "false" ]]; then
  rm -rf "$SCRIPT_DIR"
fi

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
echo -e "${YELLOW}Uninstall:${NC}"
echo "  sudo $SHARE_DIR/uninstall.sh"
echo ""
print_success "Installation complete!"