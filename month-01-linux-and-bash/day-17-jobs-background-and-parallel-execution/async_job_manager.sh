#!/usr/bin/env bash

# ==============================================================================
# Script: async_job_manager.sh
# Track: Linux & Bash Companion - Day 17 (Job Control & Asynchronous Management)
# Objective: Demonstrates lifecycle management of background/detached jobs:
#            1. Asynchronous task startup (&) with output stream redirection
#            2. Process ID isolation via .pid state locking
#            3. Process health probing via POSIX signal 0 (kill -0)
#            4. Orderly teardown via SIGTERM and PID file cleanup
#
# Usage: ./async_job_manager.sh {start|status|stop|tail-log}
# ==============================================================================

set -euo pipefail

WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${WORK_DIR}/.async_worker.pid"
LOG_FILE="${WORK_DIR}/async_worker.log"

log_info() {
  echo -e "\033[0;34m[INFO]\033[0m $*"
}

log_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $*"
}

log_warn() {
  echo -e "\033[1;33m[WARN]\033[0m $*"
}

log_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $*" >&2
}

# The simulated background workload
run_background_workload() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Asynchronous worker initialized (PID: $$)"
  local counter=1
  while true; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Heartbeat cycle $counter: Processing background queue..."
    counter=$((counter + 1))
    sleep 2
  done
}

start_worker() {
  if [[ -f "$PID_FILE" ]]; then
    local existing_pid
    existing_pid=$(cat "$PID_FILE")
    if kill -0 "$existing_pid" 2>/dev/null; then
      log_warn "Worker is already active under PID $existing_pid."
      return 0
    else
      log_warn "Stale PID file detected ($existing_pid not running). Cleaning up."
      rm -f "$PID_FILE"
    fi
  fi

  log_info "Launching asynchronous worker in background..."
  # Execute in background, redirecting stdout and stderr, disconnecting stdin
  ( run_background_workload ) < /dev/null >> "$LOG_FILE" 2>&1 &
  local worker_pid=$!

  echo "$worker_pid" > "$PID_FILE"
  log_success "Worker started successfully."
  echo "  PID       : $worker_pid"
  echo "  Log File  : $LOG_FILE"
  echo "  PID File  : $PID_FILE"
  echo "  Tip       : Run '$0 status' or '$0 tail-log' to monitor."
}

status_worker() {
  if [[ ! -f "$PID_FILE" ]]; then
    log_info "Status: STOPPED (No PID file found)"
    return 3
  fi

  local worker_pid
    worker_pid=$(cat "$PID_FILE")

  if kill -0 "$worker_pid" 2>/dev/null; then
    log_success "Status: RUNNING (PID: $worker_pid)"
    if command -v ps >/dev/null 2>&1; then
      echo "------------------------------------------------------------"
      ps -p "$worker_pid" -o pid,ppid,stat,%cpu,%mem,time,cmd 2>/dev/null || true
      echo "------------------------------------------------------------"
    fi
    return 0
  else
    log_warn "Status: DEAD / STALE (PID $worker_pid is not responding)"
    return 1
  fi
}

stop_worker() {
  if [[ ! -f "$PID_FILE" ]]; then
    log_warn "No PID file found. Worker is not running."
    return 0
  fi

  local worker_pid
  worker_pid=$(cat "$PID_FILE")

  if kill -0 "$worker_pid" 2>/dev/null; then
    log_info "Sending SIGTERM (polite shutdown) to PID $worker_pid..."
    kill -15 "$worker_pid"

    # Wait up to 5 seconds for termination
    local timeout=5
    while kill -0 "$worker_pid" 2>/dev/null && (( timeout > 0 )); do
      sleep 1
      timeout=$((timeout - 1))
    done

    if kill -0 "$worker_pid" 2>/dev/null; then
      log_warn "Process did not terminate within timeout. Sending SIGKILL..."
      kill -9 "$worker_pid" 2>/dev/null || true
    fi

    log_success "Worker PID $worker_pid stopped."
  else
    log_warn "Process $worker_pid was already stopped."
  fi

  rm -f "$PID_FILE"
  log_info "PID file removed."
}

tail_log() {
  if [[ ! -f "$LOG_FILE" ]]; then
    log_warn "Log file does not exist yet: $LOG_FILE"
    return 1
  fi
  log_info "Streaming last 10 lines from $LOG_FILE (Press Ctrl+C to exit):"
  tail -n 10 -f "$LOG_FILE"
}

case "${1:-}" in
  start)
    start_worker
    ;;
  status)
    status_worker
    ;;
  stop)
    stop_worker
    ;;
  tail-log)
    tail_log
    ;;
  *)
    echo "Usage: $0 {start|status|stop|tail-log}"
    exit 1
    ;;
esac
