#!/usr/bin/env bash

# ==============================================================================
# Script: service_sentinel.sh
# Track: Bash Companion - Day 18 (Scripting Services & systemd)
# Objective: Production-grade Systemd service health manager & safe restarter:
#            1. Reports whether a service is active using systemctl inside an if
#            2. Restarts the service safely ONLY when it is not running
#            3. Emits a clean, one-line human-readable status for monitoring
#            4. Performs pre-restart sanity validation (e.g. nginx -t) when supported
#
# Usage:
#   ./service_sentinel.sh [OPTIONS] [SERVICE_NAME]
#
# Examples:
#   ./service_sentinel.sh nginx
#   ./service_sentinel.sh --heal nginx
#   ./service_sentinel.sh --diagnose nginx
#   ./service_sentinel.sh --mock-state inactive nginx
# ==============================================================================

set -euo pipefail

# Visual color indicators
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SERVICE="nginx"
ACTION="check" # check, heal, diagnose
MOCK_STATE=""   # Optional mock state for environments without systemd: active, inactive, failed
DRY_RUN=false

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] [SERVICE_NAME]

Options:
  -c, --check            Check service status and report a clean 1-line summary (default)
  -r, --heal             Safe auto-restart: restart service ONLY if it is down/failed
  -d, --diagnose         Show extended status diagnosis (PID, memory, cgroup)
  -n, --dry-run          Simulate actions without executing systemctl restart
  -m, --mock-state STATE Simulate service state (active, inactive, failed)
  -h, --help             Display this help message and exit

Examples:
  $(basename "$0") nginx
  $(basename "$0") --heal nginx
  $(basename "$0") --diagnose nginx
EOF
  exit 0
}

# Parse command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--check)
      ACTION="check"
      shift
      ;;
    -r|--heal|--restart-if-down)
      ACTION="heal"
      shift
      ;;
    -d|--diagnose)
      ACTION="diagnose"
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -m|--mock-state)
      MOCK_STATE="$2"
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
      SERVICE="$1"
      shift
      ;;
  esac
done

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Function: Query service state
get_service_state() {
  local svc="$1"

  if [[ -n "$MOCK_STATE" ]]; then
    echo "$MOCK_STATE"
    return 0
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    # Fallback if systemctl is not available (e.g. docker container / Windows / BSD)
    if pgrep -x "$svc" >/dev/null 2>&1; then
      echo "active"
    else
      echo "inactive"
    fi
    return 0
  fi

  # systemctl is-active prints: active, inactive, failed, activating, or deactivating
  local state
  state=$(systemctl is-active "$svc" 2>/dev/null || true)
  if [[ -z "$state" ]]; then
    state="unknown"
  fi
  echo "$state"
}

# Function: Retrieve main PID if available
get_service_pid() {
  local svc="$1"
  if [[ -n "$MOCK_STATE" ]]; then
    if [[ "$MOCK_STATE" == "active" ]]; then
      echo "48102"
    else
      echo "N/A"
    fi
    return 0
  fi

  if command -v systemctl >/dev/null 2>&1; then
    local pid
    pid=$(systemctl show --property MainPID --value "$svc" 2>/dev/null || true)
    if [[ -n "$pid" && "$pid" != "0" ]]; then
      echo "$pid"
      return 0
    fi
  fi

  local proc_pid
  proc_pid=$(pgrep -x "$svc" | head -n 1 || true)
  if [[ -n "$proc_pid" ]]; then
    echo "$proc_pid"
  else
    echo "N/A"
  fi
}

# Pre-restart configuration check (prevents restart death-spirals on syntax errors)
validate_service_config() {
  local svc="$1"
  if [[ "$svc" == "nginx" ]] && command -v nginx >/dev/null 2>&1; then
    if ! nginx -t >/dev/null 2>&1; then
      return 1
    fi
  fi
  return 0
}

# Main Execution Flow
CURRENT_STATE=$(get_service_state "$SERVICE")
MAIN_PID=$(get_service_pid "$SERVICE")

case "$ACTION" in
  check)
    # Task b18-service-status & b18-report: Report active status in one clean line
    if [[ "$CURRENT_STATE" == "active" ]]; then
      echo -e "${GREEN}[ACTIVE]${NC} [$(timestamp)] Service '${BOLD}${SERVICE}${NC}' is running normally (PID: ${MAIN_PID})."
      exit 0
    else
      echo -e "${RED}[DOWN]${NC} [$(timestamp)] Service '${BOLD}${SERVICE}${NC}' is ${CURRENT_STATE} (PID: ${MAIN_PID})."
      exit 1
    fi
    ;;

  heal)
    # Task b18-restart-safe: Restart the service ONLY when it is not running
    if [[ "$CURRENT_STATE" == "active" ]]; then
      echo -e "${GREEN}[OK]${NC} [$(timestamp)] Service '${BOLD}${SERVICE}${NC}' is already active (PID: ${MAIN_PID}). No action needed."
      exit 0
    fi

    echo -e "${YELLOW}[HEALING]${NC} [$(timestamp)] Service '${BOLD}${SERVICE}${NC}' is ${CURRENT_STATE}. Initiating recovery sequence..."

    # Check configuration syntax before restarting
    if ! validate_service_config "$SERVICE"; then
      echo -e "${RED}[ABORT]${NC} [$(timestamp)] Configuration validation failed for '${SERVICE}'. Refusing to restart to avoid crash-loop." >&2
      echo -e "${YELLOW}[TIP]${NC} Run '${SERVICE} -t' or check configuration syntax before restarting." >&2
      exit 2
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo -e "${CYAN}[DRY-RUN]${NC} Would execute: sudo systemctl restart ${SERVICE}"
      exit 0
    fi

    # Attempt restart
    if [[ -n "$MOCK_STATE" ]]; then
      echo -e "${CYAN}[MOCK]${NC} Simulated restart of ${SERVICE}."
      CURRENT_STATE="active"
      MAIN_PID="48999"
    else
      if [[ $EUID -ne 0 ]]; then
        sudo systemctl restart "$SERVICE"
      else
        systemctl restart "$SERVICE"
      fi
      # Re-evaluate state post-restart
      sleep 1
      CURRENT_STATE=$(get_service_state "$SERVICE")
      MAIN_PID=$(get_service_pid "$SERVICE")
    fi

    # Verify recovery result
    if [[ "$CURRENT_STATE" == "active" ]]; then
      echo -e "${GREEN}[RECOVERED]${NC} [$(timestamp)] Service '${BOLD}${SERVICE}${NC}' was down, now successfully restarted and active (PID: ${MAIN_PID})."
      exit 0
    else
      echo -e "${RED}[FAILED]${NC} [$(timestamp)] Attempted to restart '${BOLD}${SERVICE}${NC}', but service failed to transition to active state." >&2
      exit 1
    fi
    ;;

  diagnose)
    echo -e "${BLUE}============================================================${NC}"
    echo -e "       ${BOLD}SYSTEMD SERVICE DIAGNOSTIC REPORT${NC}                      "
    echo -e "${BLUE}============================================================${NC}"
    echo -e "Target Service : ${BOLD}${SERVICE}${NC}"
    echo -e "Current State  : ${CURRENT_STATE}"
    echo -e "Main Process ID: ${MAIN_PID}"
    echo -e "Audit Timestamp: $(timestamp)"
    echo -e "${BLUE}------------------------------------------------------------${NC}"

    if command -v systemctl >/dev/null 2>&1; then
      echo -e "${BOLD}Unit Properties:${NC}"
      systemctl show "$SERVICE" --property=Id,UnitFileState,ActiveState,SubState,LoadState,MemoryCurrent,NTasks 2>/dev/null || true
      echo -e "${BLUE}------------------------------------------------------------${NC}"
      echo -e "${BOLD}Recent Journal Entries (Last 5 lines):${NC}"
      journalctl -u "$SERVICE" -n 5 --no-pager 2>/dev/null || echo "No journal entries found."
    else
      echo -e "systemctl not found in current PATH. Basic diagnosis complete."
    fi
    echo -e "${BLUE}============================================================${NC}"
    ;;
esac
