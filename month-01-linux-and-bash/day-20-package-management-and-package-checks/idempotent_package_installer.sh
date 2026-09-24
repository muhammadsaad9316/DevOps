#!/usr/bin/env bash

# ==============================================================================
# Script: idempotent_package_installer.sh
# Track: Bash Companion - Day 20 (Scripting Package Checks)
# Objective: Production-grade idempotent software provisioning script:
#            1. Checks whether a software package is already installed
#            2. Installs the package safely ONLY when it is missing
#            3. Loops over an array of 5 packages and reports individual statuses
#            4. Provides clear, colorized, one-line status summaries
#            5. Enforces non-interactive execution (DEBIAN_FRONTEND=noninteractive)
#
# Usage:
#   ./idempotent_package_installer.sh [OPTIONS] [PKG1 PKG2 ...]
#
# Examples:
#   ./idempotent_package_installer.sh
#   ./idempotent_package_installer.sh --install
#   ./idempotent_package_installer.sh --dry-run --install
#   ./idempotent_package_installer.sh --mock-missing "tree,jq" --install
# ==============================================================================

set -euo pipefail

# Visual color indicators
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default 5 essential DevOps packages to audit/manage (Task b20-list-loop)
DEFAULT_PACKAGES=("git" "curl" "tree" "jq" "htop")
INSTALL_MODE=false
DRY_RUN=false
MOCK_MISSING=""

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] [PACKAGE_NAMES...]

Arguments:
  PACKAGE_NAMES         Optional list of packages (default: ${DEFAULT_PACKAGES[*]})

Options:
  -i, --install         Install missing packages automatically (idempotent)
  -n, --dry-run         Simulate installation commands without making changes
  --mock-missing LIST   Comma-separated list of packages to treat as missing (for testing)
  -h, --help            Show this help guide

Examples:
  $(basename "$0")                          # Audit default 5 packages
  $(basename "$0") --install                # Audit & install any missing packages
  $(basename "$0") --dry-run --install      # Preview install actions
EOF
  exit 0
}

# Parse options
CUSTOM_PACKAGES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--install)
      INSTALL_MODE=true
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    --mock-missing)
      MOCK_MISSING="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
      usage
      ;;
    *)
      CUSTOM_PACKAGES+=("$1")
      shift
      ;;
  esac
done

if [[ ${#CUSTOM_PACKAGES[@]} -gt 0 ]]; then
  PACKAGES=("${CUSTOM_PACKAGES[@]}")
else
  PACKAGES=("${DEFAULT_PACKAGES[@]}")
fi

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Task b20-check-installed: Check whether a package is installed
# Returns 0 if installed ("install ok installed"), 1 if missing
is_package_installed() {
  local pkg="$1"

  # Check mock list if provided
  if [[ -n "$MOCK_MISSING" ]]; then
    if [[ ",$MOCK_MISSING," =~ ,"$pkg", ]]; then
      return 1 # Simulated missing
    fi
  fi

  # Primary Linux Debian/Ubuntu check via dpkg-query
  if command -v dpkg-query >/dev/null 2>&1; then
    local status
    status=$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)
    if [[ "$status" == "install ok installed" ]]; then
      return 0
    else
      return 1
    fi
  fi

  # Fallback for systems where dpkg is unavailable (e.g. Git Bash, macOS, RedHat)
  if command -v "$pkg" >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

# Get installed package version
get_package_version() {
  local pkg="$1"
  if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "unknown"
  elif command -v "$pkg" >/dev/null 2>&1; then
    echo "installed (bin in PATH)"
  else
    echo "none"
  fi
}

echo -e "${BLUE}============================================================${NC}"
echo -e "       ${BOLD}IDEMPOTENT PACKAGE AUDITOR & PROVISIONER${NC}              "
echo -e "${BLUE}============================================================${NC}"
echo -e "Target Packages : ${BOLD}${PACKAGES[*]}${NC}"
echo -e "Auto-Install    : ${INSTALL_MODE}"
echo -e "Dry-Run Mode    : ${DRY_RUN}"
echo -e "Audit Timestamp : $(timestamp)"
echo -e "${BLUE}------------------------------------------------------------${NC}"

INSTALLED_COUNT=0
MISSING_COUNT=0
NEWLY_INSTALLED=0
FAILED_COUNT=0

# Task b20-list-loop: Loop over list of packages and report status of each one
for pkg in "${PACKAGES[@]}"; do
  if is_package_installed "$pkg"; then
    VERSION=$(get_package_version "$pkg")
    # Task b20-report / clear one-line result
    echo -e "${GREEN}[INSTALLED]${NC} Package '${BOLD}${pkg}${NC}' is already present (v: ${VERSION})."
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
  else
    echo -e "${YELLOW}[MISSING]${NC}   Package '${BOLD}${pkg}${NC}' is NOT installed."
    MISSING_COUNT=$((MISSING_COUNT + 1))

    # Task b20-install-if-missing: Extend to install the package only when missing
    if [[ "$INSTALL_MODE" == true ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        echo -e "            ${CYAN}[DRY-RUN] Would execute: sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ${pkg}${NC}"
      else
        echo -e "            ${BLUE}[INSTALLING] Provisioning '${pkg}' via apt-get...${NC}"
        
        # Check mock mode
        if [[ -n "$MOCK_MISSING" ]]; then
          echo -e "            ${GREEN}[MOCK-SUCCESS] Successfully simulated installation of ${pkg}.${NC}"
          NEWLY_INSTALLED=$((NEWLY_INSTALLED + 1))
        elif command -v apt-get >/dev/null 2>&1; then
          if [[ $EUID -ne 0 ]]; then
            sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null 2>&1 || true
            if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1; then
              echo -e "            ${GREEN}[SUCCESS] Installed ${pkg} successfully.${NC}"
              NEWLY_INSTALLED=$((NEWLY_INSTALLED + 1))
            else
              echo -e "            ${RED}[FAILED] apt-get install failed for ${pkg}.${NC}" >&2
              FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
          else
            DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null 2>&1 || true
            if DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1; then
              echo -e "            ${GREEN}[SUCCESS] Installed ${pkg} successfully.${NC}"
              NEWLY_INSTALLED=$((NEWLY_INSTALLED + 1))
            else
              echo -e "            ${RED}[FAILED] apt-get install failed for ${pkg}.${NC}" >&2
              FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
          fi
        else
          echo -e "            ${RED}[ERROR] apt-get not found. Cannot auto-install ${pkg}.${NC}" >&2
          FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
      fi
    fi
  fi
done

echo -e "${BLUE}------------------------------------------------------------${NC}"
echo -e "Audit Summary: Total: ${#PACKAGES[@]} | Present: ${INSTALLED_COUNT} | Missing: ${MISSING_COUNT} | Installed: ${NEWLY_INSTALLED} | Failed: ${FAILED_COUNT}"

if [[ "$MISSING_COUNT" -gt 0 && "$INSTALL_MODE" == false ]]; then
  echo -e "${YELLOW}[TIP] Run with --install to automatically provision all missing packages.${NC}"
fi
echo -e "${BLUE}============================================================${NC}"

if [[ "$FAILED_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
