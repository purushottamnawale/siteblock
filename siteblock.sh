#!/bin/bash
#
# siteblock - A simple site blocking tool using /etc/hosts
# https://github.com/purushottamnawale/siteblock
#

set -euo pipefail

# Configuration
HOSTS_FILE="/etc/hosts"
MARKER_BEGIN="# SITEBLOCK-BEGIN"
MARKER_END="# SITEBLOCK-END"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine script directory and sites file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITES_FILE="${SITEBLOCK_SITES_FILE:-$SCRIPT_DIR/sites.txt}"

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

# Check if running with appropriate permissions
check_permissions() {
  if [[ $EUID -ne 0 ]] && [[ "$1" != "status" ]] && [[ "$1" != "list" ]] && [[ "$1" != "help" ]] && [[ "$1" != "version" ]]; then
    print_error "This operation requires root privileges. Please run with sudo."
    exit 1
  fi
}

# Load sites from file (ignore empty lines and comments)
load_sites() {
  if [[ ! -f "$SITES_FILE" ]]; then
    print_error "Sites file not found: $SITES_FILE"
    print_info "Create a sites.txt file with entries like: 127.0.0.1 example.com"
    exit 1
  fi

  # Read sites into array (compatible with older bash)
  SITES=()
  while IFS= read -r line; do
    SITES+=("$line")
  done < <(grep -Ev '^[[:space:]]*(#|$)' "$SITES_FILE")

  if [[ ${#SITES[@]} -eq 0 ]]; then
    print_warning "No sites configured in $SITES_FILE"
    # We don't exit here because we might want to unblock even if sites.txt is empty
  fi
}

# Backup hosts file before modification
backup_hosts() {
  local backup_file="/etc/hosts.siteblock.bak"
  if [[ ! -f "$backup_file" ]]; then
    cp "$HOSTS_FILE" "$backup_file"
    print_info "Backup created: $backup_file"
  fi
}

block_sites() {
  load_sites

  if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    print_warning "Sites already blocked. Use 'reload' to update the block list."
    exit 0
  fi

  backup_hosts

  {
    echo ""
    echo "$MARKER_BEGIN"
    echo "# Blocked on: $(date '+%Y-%m-%d %H:%M:%S')"
    for site in "${SITES[@]}"; do
      echo "$site"
    done
    echo "$MARKER_END"
  } >> "$HOSTS_FILE"

  # Flush DNS cache if available
  flush_dns

  print_success "Blocked ${#SITES[@]} site entries."
}

unblock_sites() {
  if ! grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    print_warning "No sites are currently blocked."
    exit 0
  fi

  sed_i "/$MARKER_BEGIN/,/$MARKER_END/d" "$HOSTS_FILE"

  # Flush DNS cache if available
  flush_dns

  print_success "All sites unblocked."
}

reload_sites() {
  if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    sed_i "/$MARKER_BEGIN/,/$MARKER_END/d" "$HOSTS_FILE"
  fi

  load_sites

  {
    echo ""
    echo "$MARKER_BEGIN"
    echo "# Blocked on: $(date '+%Y-%m-%d %H:%M:%S')"
    for site in "${SITES[@]}"; do
      echo "$site"
    done
    echo "$MARKER_END"
  } >> "$HOSTS_FILE"

  flush_dns

  print_success "Block list reloaded with ${#SITES[@]} site entries."
}

add_site() {
  local domain="$1"
  if [[ -z "$domain" ]]; then
    print_error "Please provide a domain to block."
    exit 1
  fi

  # Check if already exists
  if grep -q "127.0.0.1 $domain" "$SITES_FILE"; then
    print_warning "Domain $domain is already in the list."
    return
  fi

  echo "127.0.0.1 $domain" >> "$SITES_FILE"
  print_success "Added $domain to block list."

  # Also add www. if it's not already there and the domain doesn't start with www.
  if [[ "$domain" != www.* ]]; then
    if ! grep -q "127.0.0.1 www.$domain" "$SITES_FILE"; then
      echo "127.0.0.1 www.$domain" >> "$SITES_FILE"
      print_success "Added www.$domain to block list."
    fi
  fi

  # If currently blocked, reload
  if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    print_info "Reloading block list..."
    reload_sites
  fi
}

remove_site() {
  local domain="$1"
  if [[ -z "$domain" ]]; then
    print_error "Please provide a domain to remove."
    exit 1
  fi

  # Escape dots for sed regex
  local escaped_domain="${domain//./\\.}"
  sed_i "/127\.0\.0\.1 $escaped_domain$/d" "$SITES_FILE"
  sed_i "/127\.0\.0\.1 www\.$escaped_domain$/d" "$SITES_FILE"
  
  print_success "Removed $domain and www.$domain from block list."

  # If currently blocked, reload
  if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    print_info "Reloading block list..."
    reload_sites
  fi
}

status_sites() {
  if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    print_success "Status: ${GREEN}BLOCKED${NC}"
    local count
    count=$(sed -n "/$MARKER_BEGIN/,/$MARKER_END/p" "$HOSTS_FILE" | grep -c "127.0.0.1" || echo "0")
    print_info "Currently blocking $count site entries."
  else
    print_info "Status: ${YELLOW}UNBLOCKED${NC}"
  fi
}

list_sites() {
  if [[ ! -f "$SITES_FILE" ]]; then
    print_error "Sites file not found: $SITES_FILE"
    exit 1
  fi

  print_info "Configured sites in $SITES_FILE:"
  echo ""
  grep -Ev '^[[:space:]]*(#|$)' "$SITES_FILE" | while read -r line; do
    echo "  • $line"
  done
}

flush_dns() {
  # Try to flush DNS cache (varies by system)
  if command -v systemd-resolve &> /dev/null; then
    systemd-resolve --flush-caches 2>/dev/null || true
  elif command -v resolvectl &> /dev/null; then
    resolvectl flush-caches 2>/dev/null || true
  elif command -v dscacheutil &> /dev/null; then # macOS
    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
  elif command -v nscd &> /dev/null; then
    sudo /etc/init.d/nscd restart
  fi
}

show_version() {
  echo "siteblock version $VERSION"
}

show_help() {
  cat << EOF
${BLUE}siteblock${NC} - Block distracting websites using /etc/hosts

${YELLOW}USAGE:${NC}
    siteblock <command> [arguments]

${YELLOW}COMMANDS:${NC}
    block           Add sites from sites.txt to hosts file
    unblock         Remove all blocked sites from hosts file
    add <domain>    Add a domain to the block list
    remove <domain> Remove a domain from the block list
    reload          Update block list with current sites.txt
    status          Show current blocking status
    list            Show configured sites
    version         Show version information
    uninstall       Uninstall siteblock
    help            Show this help message

${YELLOW}CONFIGURATION:${NC}
    Sites file: $SITES_FILE
    Hosts file: $HOSTS_FILE

${YELLOW}ENVIRONMENT:${NC}
    SITEBLOCK_SITES_FILE    Override default sites.txt location

${YELLOW}EXAMPLES:${NC}
    sudo siteblock block           # Start blocking sites
    sudo siteblock add facebook.com # Add facebook.com to block list
    sudo siteblock unblock         # Stop blocking sites
    siteblock status               # Check if sites are blocked

EOF
}

# Main
main() {
  local command="${1:-help}"

  check_permissions "$command"

  case "$command" in
    block)
      block_sites
      ;;
    unblock)
      unblock_sites
      ;;
    reload)
      reload_sites
      ;;
    add)
      add_site "${2:-}"
      ;;
    remove)
      remove_site "${2:-}"
      ;;
    status)
      status_sites
      ;;
    list)
      list_sites
      ;;
    version|--version|-v)
      show_version
      ;;
    uninstall)
      if [[ -f "$SCRIPT_DIR/uninstall.sh" ]]; then
        exec "$SCRIPT_DIR/uninstall.sh"
      elif [[ -f "/usr/local/share/siteblock/uninstall.sh" ]]; then
        exec "/usr/local/share/siteblock/uninstall.sh"
      else
        print_error "Uninstall script not found."
        exit 1
      fi
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      print_error "Unknown command: $command"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

main "$@"

