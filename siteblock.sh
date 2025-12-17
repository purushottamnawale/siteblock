#!/bin/bash

HOSTS_FILE="/etc/hosts"
MARKER_BEGIN="# SITEBLOCK-BEGIN"
MARKER_END="# SITEBLOCK-END"

# Determine script directory and sites file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITES_FILE="$SCRIPT_DIR/sites.txt"

# Load sites from file (ignore empty lines and comments)
if [[ ! -f "$SITES_FILE" ]]; then
  echo "Sites file not found: $SITES_FILE"
  exit 1
fi

mapfile -t SITES < <(grep -Ev '^\s*(#|$)' "$SITES_FILE")

block_sites() {
  if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    echo "Sites already blocked."
    exit 0
  fi

  {
    echo ""
    echo "$MARKER_BEGIN"
    for site in "${SITES[@]}"; do
      echo "$site"
    done
    echo "$MARKER_END"
  } | sudo tee -a "$HOSTS_FILE" > /dev/null

  echo "Sites blocked."
}

unblock_sites() {
  sudo sed -i "/$MARKER_BEGIN/,/$MARKER_END/d" "$HOSTS_FILE"
  echo "Sites unblocked."
}

status_sites() {
  if grep -q "$MARKER_BEGIN" "$HOSTS_FILE"; then
    echo "Status: BLOCKED"
  else
    echo "Status: UNBLOCKED"
  fi
}

case "$1" in
  block)
    block_sites
    ;;
  unblock)
    unblock_sites
    ;;
  status)
    status_sites
    ;;
  *)
    echo "Usage: block_sites {block|unblock|status}"
    exit 1
    ;;
esac
