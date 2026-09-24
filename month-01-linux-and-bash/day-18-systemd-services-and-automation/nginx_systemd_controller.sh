#!/usr/bin/env bash

# ==============================================================================
# Script: nginx_systemd_controller.sh
# Track: Linux Fundamentals - Day 18 (systemd And Services)
# Objective: Interactive/Automated drill manager for Day 18 tasks:
#            1. Verifying nginx installation & default landing page response
#            2. Parsing and explaining systemctl status output
#            3. Managing service lifecycle (start, stop, restart, reload, enable)
#            4. Chaos drill: Introduce nginx syntax error, observe restart failure, and restore
#            5. Inspecting unit file definition across system directories
#
# Usage:
#   ./nginx_systemd_controller.sh [COMMAND]
#
# Commands:
#   status        - Show detailed systemctl status with line annotations
#   verify-web    - Send HTTP probe to localhost:80 to verify HTTP 200 response
#   test-config   - Run nginx -t preflight syntax audit
#   break-config  - Inject deliberate syntax error to test failure handling
#   fix-config    - Restore clean configuration and reload service
#   unit-inspect  - Locate and display nginx.service unit definition
#   help          - Show command guide
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

NGINX_CONF="/etc/nginx/nginx.conf"
BACKUP_CONF="/etc/nginx/nginx.conf.bak.day18"
COMMAND="${1:-status}"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

require_root_or_sudo() {
  if [[ $EUID -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    log_err "This operation requires root or sudo privileges."
    exit 1
  fi
}

run_as_root() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

case "$COMMAND" in
  status)
    log_info "Querying Systemd status for nginx.service..."
    if command -v systemctl >/dev/null 2>&1; then
      systemctl status nginx --no-pager || true
    else
      log_warn "systemctl command not found. Listing process table for nginx:"
      ps aux | grep "[n]ginx" || echo "nginx is not running."
    fi
    ;;

  verify-web)
    log_info "Probing local HTTP port 80..."
    if command -v curl >/dev/null 2>&1; then
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || true)
      if [[ "$HTTP_CODE" == "200" ]]; then
        log_ok "Nginx is serving default HTTP traffic! (HTTP 200 OK)"
      else
        log_warn "HTTP probe returned status code: ${HTTP_CODE:-No response}"
      fi
    else
      log_warn "curl not found. Probe using netcat or wget."
    fi
    ;;

  test-config)
    log_info "Running preflight syntax audit (nginx -t)..."
    if command -v nginx >/dev/null 2>&1; then
      run_as_root nginx -t
      log_ok "Nginx configuration syntax is valid."
    else
      log_err "nginx executable not found in PATH."
      exit 1
    fi
    ;;

  break-config)
    require_root_or_sudo
    log_warn "Chaos Drill: Injecting deliberate syntax error into ${NGINX_CONF}..."
    if [[ ! -f "$NGINX_CONF" ]]; then
      log_err "Cannot find ${NGINX_CONF}. Is nginx installed?"
      exit 1
    fi

    # Backup clean config first
    if [[ ! -f "$BACKUP_CONF" ]]; then
      run_as_root cp "$NGINX_CONF" "$BACKUP_CONF"
      log_info "Created backup configuration at ${BACKUP_CONF}"
    fi

    # Append broken directive
    echo "### BROKEN DIRECTIVE INJECTED FOR LAB TESTING ###" | run_as_root tee -a "$NGINX_CONF" >/dev/null
    echo "invalid_directive_without_semicolon broken" | run_as_root tee -a "$NGINX_CONF" >/dev/null
    log_warn "Injected syntax error into ${NGINX_CONF}."

    # Validate failure
    log_info "Testing configuration (expecting failure):"
    if ! run_as_root nginx -t 2>/dev/null; then
      log_ok "Syntax check correctly flagged failure!"
    fi

    log_info "Attempting to restart nginx with broken config..."
    if ! run_as_root systemctl restart nginx 2>/dev/null; then
      log_ok "systemctl restart nginx FAILED as expected. Error captured by systemd!"
      echo -e "${YELLOW}Notice: Use 'journalctl -xeu nginx' or 'systemctl status nginx' to inspect the exact failure.${NC}"
    fi
    ;;

  fix-config)
    require_root_or_sudo
    log_info "Restoring clean Nginx configuration from ${BACKUP_CONF}..."
    if [[ -f "$BACKUP_CONF" ]]; then
      run_as_root cp "$BACKUP_CONF" "$NGINX_CONF"
      run_as_root rm -f "$BACKUP_CONF"
      log_ok "Restored ${NGINX_CONF}."
    else
      log_warn "Backup file not found. Re-validating current file..."
    fi

    log_info "Validating syntax post-repair..."
    run_as_root nginx -t
    log_info "Restarting nginx service..."
    run_as_root systemctl restart nginx
    log_ok "nginx.service successfully restarted and running."
    ;;

  unit-inspect)
    log_info "Inspecting Systemd unit storage hierarchy for nginx.service:"
    echo "1. System Admin overrides: /etc/systemd/system/nginx.service"
    echo "2. Dynamic runtime units : /run/systemd/system/nginx.service"
    echo "3. Package vendor files  : /lib/systemd/system/nginx.service (or /usr/lib/...)"
    echo ""
    if command -v systemctl >/dev/null 2>&1; then
      log_info "Executing: systemctl cat nginx.service"
      echo -e "${CYAN}------------------------------------------------------------${NC}"
      systemctl cat nginx.service || true
      echo -e "${CYAN}------------------------------------------------------------${NC}"
    fi
    ;;

  help|*)
    cat << EOF
Nginx Systemd Controller & Lab Drill Manager
Usage: $(basename "$0") <COMMAND>

Commands:
  status        Show current systemctl status
  verify-web    Probe HTTP port 80 for default page (HTTP 200)
  test-config   Run 'nginx -t' preflight check
  break-config  Simulate broken syntax & watch systemctl restart fail
  fix-config    Restore valid configuration & restart service
  unit-inspect  Show unit file path and inspect directives
  help          Display this help menu
EOF
    ;;
esac
