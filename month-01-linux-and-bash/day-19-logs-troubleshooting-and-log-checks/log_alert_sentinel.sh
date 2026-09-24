#!/usr/bin/env bash

# ==============================================================================
# Script: log_alert_sentinel.sh
# Track: Bash Companion - Day 19 (Scripting Log Checks)
# Objective: Production-grade log parser and threshold-based alert generator:
#            1. Searches a log file for a specific word/pattern passed as argument
#            2. Accurately counts matching occurrences using grep -c (no inefficient loops)
#            3. Emits warnings or critical alerts when match counts exceed defined thresholds
#            4. Provides formatted sample extraction and built-in demo log generator
#
# Usage:
#   ./log_alert_sentinel.sh [OPTIONS] <LOG_FILE> <PATTERN>
#
# Examples:
#   ./log_alert_sentinel.sh /var/log/syslog "ERROR"
#   ./log_alert_sentinel.sh --warn 5 --crit 15 /var/log/nginx/error.log "failed"
#   ./log_alert_sentinel.sh --generate-sample-log ./sample.log
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

WARN_THRESHOLD=5
CRIT_THRESHOLD=10
SHOW_SAMPLE=3
GENERATE_SAMPLE=""

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] <LOG_FILE> <SEARCH_PATTERN>

Arguments:
  LOG_FILE              Path to the target log file to inspect
  SEARCH_PATTERN        The string or regex pattern to search for (e.g. "ERROR", "fatal")

Options:
  -w, --warn N          Warning alert threshold count (default: 5)
  -c, --crit N          Critical alert threshold count (default: 10)
  -s, --sample N        Number of recent matching lines to display (default: 3)
  --generate-sample F   Generate a synthetic production log file at path F for testing
  -h, --help            Show this help guide

Examples:
  $(basename "$0") /var/log/syslog "systemd"
  $(basename "$0") -w 3 -c 8 /var/log/nginx/error.log "connect() failed"
  $(basename "$0") --generate-sample demo.log && $(basename "$0") -w 2 -c 5 demo.log "ERROR"
EOF
  exit 0
}

# Parse options
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--warn)
      WARN_THRESHOLD="$2"
      shift 2
      ;;
    -c|--crit)
      CRIT_THRESHOLD="$2"
      shift 2
      ;;
    -s|--sample)
      SHOW_SAMPLE="$2"
      shift 2
      ;;
    --generate-sample)
      GENERATE_SAMPLE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo -e "${RED}[ERROR]${NC} Unknown argument: $1" >&2
      usage
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Generator for synthetic log testing
if [[ -n "$GENERATE_SAMPLE" ]]; then
  echo -e "${BLUE}[INFO]${NC} Generating synthetic test log at: ${GENERATE_SAMPLE}..."
  cat << 'EOF' > "$GENERATE_SAMPLE"
2026-09-24 04:00:01 INFO [worker-01] Health check passed (latency: 12ms)
2026-09-24 04:05:12 INFO [auth-service] User session token refreshed for uid 104
2026-09-24 04:10:33 ERROR [db-pool] Connection pool timeout: failed to acquire connection after 3000ms
2026-09-24 04:11:02 WARN [redis-cache] Key eviction rate elevated (mem: 88%)
2026-09-24 04:12:15 ERROR [api-gw] Upstream returned 502 Bad Gateway for /v1/checkout
2026-09-24 04:12:18 ERROR [api-gw] Upstream returned 502 Bad Gateway for /v1/orders
2026-09-24 04:13:00 INFO [worker-02] Cron schedule synchronized
2026-09-24 04:14:45 ERROR [db-pool] Connection pool timeout: retry 2 failed
2026-09-24 04:15:02 ERROR [api-gw] Circuit breaker tripped open for checkout-cluster
2026-09-24 04:15:10 CRITICAL [health-check] Outage alert: 4 of 6 health checks failing
2026-09-24 04:15:30 ERROR [billing-srv] Card charge authorization failed: timeout
EOF
  echo -e "${GREEN}[SUCCESS]${NC} Synthetic test log created (${GENERATE_SAMPLE})."
  if [[ ${#POSITIONAL[@]} -eq 0 ]]; then
    exit 0
  fi
fi

if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
  echo -e "${RED}[ERROR]${NC} Both LOG_FILE and SEARCH_PATTERN arguments are required." >&2
  usage
fi

LOG_FILE="${POSITIONAL[0]}"
PATTERN="${POSITIONAL[1]}"

# Validation checks
if [[ ! -e "$LOG_FILE" ]]; then
  echo -e "${RED}[ERROR]${NC} Target log file does not exist: ${LOG_FILE}" >&2
  exit 2
fi

if [[ ! -r "$LOG_FILE" ]]; then
  echo -e "${RED}[ERROR]${NC} Permission denied: Cannot read ${LOG_FILE}. (Try running with sudo if inspecting /var/log/)" >&2
  exit 2
fi

# Task b19-count-errors: Count matches efficiently via grep -c
# Note: grep -c returns exit code 1 if 0 matches are found, so we handle it defensively
MATCH_COUNT=$(grep -c -E "$PATTERN" "$LOG_FILE" 2>/dev/null || true)
MATCH_COUNT=${MATCH_COUNT:-0}

# Task b19-alert-threshold & b19-grep-in-script:
# Compare match count against thresholds and print single-line or multi-line alert
if [[ "$MATCH_COUNT" -ge "$CRIT_THRESHOLD" ]]; then
  echo -e "${RED}${BOLD}[CRITICAL ALERT]${NC} [$(timestamp)] Pattern '${BOLD}${PATTERN}${NC}' appeared ${BOLD}${MATCH_COUNT}${NC} times in '${LOG_FILE}' (Exceeds Critical Threshold: ${CRIT_THRESHOLD})!"
  SEVERITY=critical
elif [[ "$MATCH_COUNT" -ge "$WARN_THRESHOLD" ]]; then
  echo -e "${YELLOW}${BOLD}[WARNING ALERT]${NC} [$(timestamp)] Pattern '${BOLD}${PATTERN}${NC}' appeared ${BOLD}${MATCH_COUNT}${NC} times in '${LOG_FILE}' (Exceeds Warning Threshold: ${WARN_THRESHOLD})."
  SEVERITY=warning
elif [[ "$MATCH_COUNT" -gt 0 ]]; then
  echo -e "${GREEN}[INFO]${NC} [$(timestamp)] Pattern '${BOLD}${PATTERN}${NC}' found ${MATCH_COUNT} time(s) in '${LOG_FILE}' (Within nominal limits < ${WARN_THRESHOLD})."
  SEVERITY=ok
else
  echo -e "${GREEN}[OK]${NC} [$(timestamp)] No occurrences of pattern '${BOLD}${PATTERN}${NC}' found in '${LOG_FILE}'."
  exit 0
fi

# Display recent offending lines if matches exist and sample size > 0
if [[ "$MATCH_COUNT" -gt 0 && "$SHOW_SAMPLE" -gt 0 ]]; then
  echo -e "${CYAN}--- Recent Offending Log Entries (Last ${SHOW_SAMPLE}) ---${NC}"
  grep -E "$PATTERN" "$LOG_FILE" | tail -n "$SHOW_SAMPLE" | while IFS= read -r line; do
    echo -e "  » ${line}"
  done
  echo -e "${CYAN}--------------------------------------------------${NC}"
fi

# Set appropriate exit code for alerting pipelines (CI/CD / Monitoring)
if [[ "$SEVERITY" == "critical" ]]; then
  exit 2
elif [[ "$SEVERITY" == "warning" ]]; then
  exit 1
else
  exit 0
fi
