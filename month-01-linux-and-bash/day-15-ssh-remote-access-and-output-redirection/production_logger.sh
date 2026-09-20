#!/usr/bin/env bash

# ==============================================================================
# Script: production_logger.sh
# Track: Bash Companion - Day 15
# Objective: Demonstrate production-grade stream redirection:
#            1. Redirect normal output (stdout) to application log (append mode >>)
#            2. Redirect diagnostic/error output (stderr) to separate error log (2>>)
#            3. Formatted timestamps & process identification
#
# Usage: ./production_logger.sh [target_dir]
# ==============================================================================

set -euo pipefail

LOG_DIR="${1:-./logs}"
mkdir -p "$LOG_DIR"

APP_LOG="${LOG_DIR}/application.log"
ERR_LOG="${LOG_DIR}/error.log"

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Logging helper functions
log_info() {
  local msg="$1"
  # Write formatted log entry to APP_LOG (stdout append)
  echo "[$(timestamp)] [INFO] [PID:$$] $msg" >> "$APP_LOG"
  echo "ℹ️  $msg"
}

log_warn() {
  local msg="$1"
  echo "[$(timestamp)] [WARN] [PID:$$] $msg" >> "$APP_LOG"
  echo "⚠️  $msg"
}

log_error() {
  local msg="$1"
  # Write formatted error entry to ERR_LOG (stderr append)
  echo "[$(timestamp)] [ERROR] [PID:$$] $msg" >> "$ERR_LOG"
  # Also echo to console stderr
  echo "❌ [ERROR] $msg" >&2
}

# ------------------------------------------------------------------------------
# Execution Workflow
# ------------------------------------------------------------------------------
log_info "Initializing production logging demonstration..."
log_info "Application log stream mapped to: $APP_LOG"
log_info "Error log stream mapped to: $ERR_LOG"

# Simulate task steps
log_info "Starting environment verification..."
if command -v ssh >/dev/null 2>&1; then
  log_info "OpenSSH client binary discovered: $(command -v ssh)"
else
  log_error "OpenSSH client binary not found in system PATH!"
fi

# Simulate simulated error condition
SIMULATED_FAILS=("/nonexistent/config.conf" "/var/log/restricted.log")
for target in "${SIMULATED_FAILS[@]}"; do
  if [[ ! -f "$target" ]]; then
    log_warn "Target resource not found: $target (proceeding with fallback)"
    # Log specific failure to separate error file using standard file descriptor 2
    echo "[$(timestamp)] [STDERR] Unable to access $target" >> "$ERR_LOG"
  fi
done

log_info "Batch process completed successfully."

echo ""
echo "=== Application Log Snippet ($APP_LOG) ==="
tail -n 5 "$APP_LOG"

echo ""
echo "=== Error Log Snippet ($ERR_LOG) ==="
tail -n 5 "$ERR_LOG"

exit 0
