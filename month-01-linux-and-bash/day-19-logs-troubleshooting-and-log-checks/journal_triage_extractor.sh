#!/usr/bin/env bash

# ==============================================================================
# Script: journal_triage_extractor.sh
# Track: Linux Fundamentals - Day 19 (Logs And Troubleshooting)
# Objective: Incident triage assistant wrapping systemd-journald:
#            1. Query and page journalctl logs cleanly without pagination lockups
#            2. Filter logs by systemd unit (-u)
#            3. Filter logs by time window (--since / --until)
#            4. Extract high-priority errors (-p err..emerg)
#            5. Perform root-cause diagnosis for failed services (d19-find-error)
#
# Usage:
#   ./journal_triage_extractor.sh [COMMAND] [OPTIONS]
#
# Commands:
#   errors        Extract priority error lines for a service or entire system
#   stream        Follow service logs live (-f)
#   window        Filter logs within a specific time window
#   diagnose      Locate root-cause crash reason for a failed service
#   help          Show command reference
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

COMMAND="${1:-errors}"
SERVICE="nginx"
TIME_WINDOW="15m ago"
LINES=20

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

case "$COMMAND" in
  errors)
    SVC="${2:-$SERVICE}"
    log_info "Searching journal for errors related to '${SVC}' (Priority: Error to Emergency)..."
    if command -v journalctl >/dev/null 2>&1; then
      echo -e "${RED}--- Critical / Error Log Entries for ${SVC} ---${NC}"
      journalctl -u "$SVC" -p 0..3 --no-pager -n "$LINES" || true
      echo -e "${RED}------------------------------------------------${NC}"
    else
      log_warn "journalctl not available in current environment. Checking local syslog / mock fallback:"
      if [[ -f "/var/log/nginx/error.log" ]]; then
        tail -n "$LINES" /var/log/nginx/error.log
      else
        echo "No standard error log found."
      fi
    fi
    ;;

  stream)
    SVC="${2:-$SERVICE}"
    log_info "Attaching live stream follower to '${SVC}'. (Press Ctrl+C to detach)..."
    if command -v journalctl >/dev/null 2>&1; then
      journalctl -u "$SVC" -f
    else
      log_err "journalctl is required for streaming."
      exit 1
    fi
    ;;

  window)
    SVC="${2:-$SERVICE}"
    WINDOW="${3:-$TIME_WINDOW}"
    log_info "Querying logs for '${SVC}' since '${WINDOW}'..."
    if command -v journalctl >/dev/null 2>&1; then
      journalctl -u "$SVC" --since "$WINDOW" --no-pager
    else
      log_err "journalctl is required for time-window querying."
      exit 1
    fi
    ;;

  diagnose)
    SVC="${2:-$SERVICE}"
    log_info "Running root-cause analysis triage for service '${SVC}'..."
    if command -v journalctl >/dev/null 2>&1; then
      echo -e "${YELLOW}=== 1. Checking Service Failure State ===${NC}"
      systemctl is-failed "$SVC" 2>/dev/null && echo "Status: Service is currently in FAILED state." || echo "Status: Service is not flagged as failed."
      
      echo -e "\n${YELLOW}=== 2. Isolating Exact Error Lines from journalctl -xeu ===${NC}"
      journalctl -xeu "$SVC" --no-pager -n 15 || true
      
      echo -e "\n${YELLOW}=== 3. Extracted Root Cause Keywords (fail, error, denied, invalid) ===${NC}"
      journalctl -u "$SVC" -n 50 --no-pager 2>/dev/null | grep -iE "fail|error|denied|invalid|emerg|fatal|cannot" | tail -n 5 || echo "No explicit keyword matches found."
    else
      log_warn "journalctl not found on this system."
    fi
    ;;

  help|*)
    cat << EOF
Journal Triage Extractor & SRE Incident Assistant
Usage: $(basename "$0") <COMMAND> [SERVICE] [EXTRA_ARG]

Commands:
  errors    [service]         Display recent errors/crashes (Priority err..emerg)
  stream    [service]         Follow logs in real-time (journalctl -f -u service)
  window    [service] [since] View logs within time window (e.g. "1 hour ago", "-30m")
  diagnose  [service]         Automated root-cause triage (journalctl -xeu isolation)
  help                        Show this guide

Examples:
  $(basename "$0") errors nginx
  $(basename "$0") window nginx "20 minutes ago"
  $(basename "$0") diagnose nginx
EOF
    ;;
esac
