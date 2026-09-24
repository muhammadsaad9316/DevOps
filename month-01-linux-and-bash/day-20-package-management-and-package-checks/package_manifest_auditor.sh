#!/usr/bin/env bash

# ==============================================================================
# Script: package_manifest_auditor.sh
# Track: Linux Fundamentals - Day 20 (Installing Software)
# Objective: Package inspection, forensic file ownership & repository audit utility:
#            1. Look up which Debian package owns a specific binary or file (dpkg -S)
#            2. Query package metadata and upstream dependencies (apt show / apt search)
#            3. Audit system APT repository sources (/etc/apt/sources.list)
#            4. Explain differences between apt remove and apt purge
#
# Usage:
#   ./package_manifest_auditor.sh [COMMAND] [ARGS...]
#
# Commands:
#   who-owns <FILE_PATH>    Identify which package owns a specific file (dpkg -S)
#   inspect  <PACKAGE_NAME> Show package details, dependencies & size (apt show)
#   search   <KEYWORD>      Search repository packages (apt search)
#   repos                   Audit configured APT repository sources and GPG keys
#   compare-removal         Demonstrate filesystem impact of remove vs purge
#   help                    Show command reference
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

COMMAND="${1:-help}"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

case "$COMMAND" in
  who-owns)
    FILE_PATH="${2:-}"
    if [[ -z "$FILE_PATH" ]]; then
      log_err "File path required. Example: $0 who-owns /usr/bin/curl"
      exit 1
    fi
    log_info "Querying dpkg database for file ownership of '${FILE_PATH}'..."
    if command -v dpkg >/dev/null 2>&1; then
      dpkg -S "$FILE_PATH" || log_warn "No installed package owns file '${FILE_PATH}'."
    else
      log_warn "dpkg not available in current environment."
    fi
    ;;

  inspect)
    PKG="${2:-}"
    if [[ -z "$PKG" ]]; then
      log_err "Package name required. Example: $0 inspect curl"
      exit 1
    fi
    log_info "Extracting metadata for package '${PKG}' via apt show..."
    if command -v apt-cache >/dev/null 2>&1; then
      apt-cache show "$PKG" | grep -E "^(Package|Version|Section|Installed-Size|Depends|Homepage|Description):" | head -n 12
    elif command -v apt >/dev/null 2>&1; then
      apt show "$PKG" 2>/dev/null | grep -E "^(Package|Version|Section|Installed-Size|Depends|Homepage|Description):" | head -n 12
    else
      log_warn "apt / apt-cache not available in this environment."
    fi
    ;;

  search)
    KEYWORD="${2:-}"
    if [[ -z "$KEYWORD" ]]; then
      log_err "Search keyword required. Example: $0 search 'network scanner'"
      exit 1
    fi
    log_info "Searching repository index for '${KEYWORD}'..."
    if command -v apt-cache >/dev/null 2>&1; then
      apt-cache search "$KEYWORD" | head -n 15
    elif command -v apt >/dev/null 2>&1; then
      apt search "$KEYWORD" 2>/dev/null | head -n 20
    else
      log_warn "apt not available in this environment."
    fi
    ;;

  repos)
    log_info "Auditing configured APT repository sources..."
    SOURCES_LIST="/etc/apt/sources.list"
    SOURCES_DIR="/etc/apt/sources.list.d"

    echo -e "\n${BOLD}=== Main Repository Sources (${SOURCES_LIST}) ===${NC}"
    if [[ -f "$SOURCES_LIST" ]]; then
      grep -v -E "^\s*#|^\s*$" "$SOURCES_LIST" || echo "No active uncommented entries."
    else
      echo "File not found or not accessible."
    fi

    echo -e "\n${BOLD}=== Modular Repository Sources (${SOURCES_DIR}/*.list) ===${NC}"
    if [[ -d "$SOURCES_DIR" ]]; then
      find "$SOURCES_DIR" -type f -name "*.list" -exec echo "--- File: {} ---" \; -exec grep -v -E "^\s*#|^\s*$" {} \; || echo "No additional repo files."
    else
      echo "Directory not found."
    fi
    ;;

  compare-removal)
    echo -e "${BLUE}============================================================${NC}"
    echo -e "       ${BOLD}APT REMOVE vs APT PURGE ARCHITECTURAL COMPARISON${NC}     "
    echo -e "${BLUE}============================================================${NC}"
    cat << 'EOF'
Command: sudo apt remove <package>
  • Unlinks and deletes application binaries (e.g. /usr/bin/nginx)
  • Removes documentation and shared libraries (unless needed by others)
  • PRESERVES configuration files in /etc/ (e.g. /etc/nginx/nginx.conf remains intact)
  • DPKG Status becomes: 'rc' (Config-Files remain)
  • Use Case: Upgrading or temporary uninstall where you want your custom config saved.

Command: sudo apt purge <package>  (or apt remove --purge)
  • Unlinks binaries and libraries
  • COMPLETELY DELETES configuration files in /etc/
  • DPKG Status becomes: 'un' (Not-Installed, no trace left)
  • Use Case: Complete cleanup of a corrupted installation to start 100% fresh.

Command: sudo apt autoremove
  • Cleans orphan dependencies originally pulled in by other packages that are now gone.
EOF
    echo -e "${BLUE}============================================================${NC}"
    ;;

  help|*)
    cat << EOF
Package Manifest Auditor & Software Intelligence CLI
Usage: $(basename "$0") <COMMAND> [ARGS...]

Commands:
  who-owns        <path>      Find which package owns a specific file (dpkg -S)
  inspect         <pkg>       Display package details & dependencies (apt show)
  search          <keyword>   Search repository packages (apt search)
  repos                       Inspect configured APT repository mirrors
  compare-removal             Show detailed remove vs purge architectural breakdown
  help                        Show this guide

Examples:
  $(basename "$0") who-owns /usr/bin/curl
  $(basename "$0") inspect tree
  $(basename "$0") search "json parser"
  $(basename "$0") repos
  $(basename "$0") compare-removal
EOF
    ;;
esac
