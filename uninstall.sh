#!/bin/bash
#
# siteblock uninstaller
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Cross-platform sed in-place editing
sed_i() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Parse arguments
REMOVE_ALL=false
for arg in "$@"; do
  case "$arg" in
    --all|-a)
      REMOVE_ALL=true
      ;;
  esac
done

# Check for root
if [[ $EUID -ne 0 ]]; then
  print_error "This uninstaller must be run as root (use sudo)"
  exit 1
fi

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║        siteblock uninstaller          ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Unblock sites first
HOSTS_FILE="/etc/hosts"
MARKER_BEGIN="# SITEBLOCK-BEGIN"
MARKER_END="# SITEBLOCK-END"

if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
  print_info "Removing blocked sites from hosts file..."
  sed_i "/$MARKER_BEGIN/,/$MARKER_END/d" "$HOSTS_FILE"
  print_success "Sites unblocked"
fi

# Remove files
print_info "Removing installed files..."

if [[ -f /usr/local/bin/siteblock ]]; then
  rm /usr/local/bin/siteblock
  print_success "Removed /usr/local/bin/siteblock"
fi

if [[ -d /usr/local/share/siteblock ]]; then
  rm -rf /usr/local/share/siteblock
  print_success "Removed /usr/local/share/siteblock"
fi

# Ask about config (skip if --all flag or non-interactive)
if [[ -d /etc/siteblock ]]; then
  if [[ "$REMOVE_ALL" == "true" ]] || [[ ! -t 0 ]]; then
    rm -rf /etc/siteblock
    print_success "Removed /etc/siteblock"
  else
    echo ""
    read -p "Remove configuration directory /etc/siteblock? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf /etc/siteblock
      print_success "Removed /etc/siteblock"
    else
      print_info "Kept /etc/siteblock (you can remove it manually later)"
    fi
  fi
fi

# Remove backup if exists (skip if --all flag or non-interactive)
if [[ -f /etc/hosts.siteblock.bak ]]; then
  if [[ "$REMOVE_ALL" == "true" ]] || [[ ! -t 0 ]]; then
    rm /etc/hosts.siteblock.bak
    print_success "Removed backup file"
  else
    echo ""
    read -p "Remove hosts backup /etc/hosts.siteblock.bak? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm /etc/hosts.siteblock.bak
      print_success "Removed backup file"
    fi
  fi
fi

echo ""
print_success "Uninstallation complete!"
