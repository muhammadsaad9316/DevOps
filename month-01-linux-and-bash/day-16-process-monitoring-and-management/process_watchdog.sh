#!/usr/bin/env bash

# ==============================================================================
# Script: process_watchdog.sh
# Track: Bash Companion - Day 16
# Objective: Production process supervisor & watchdog:
#            1. Check whether a named process is currently running
#            2. Report PID and execution metrics
#            3. Automatically launch the process if dead
#            4. Maintain state via a PID lock file
#
# Usage: ./process_watchdog.sh <process_name> [start_command]
# Example: ./process_watchdog.sh nginx "sudo systemctl start nginx"
# ==============================================================================

set -euo pipefail

PROCESS_NAME="${1:-}"
START_COMMAND="${2:-}"
RUN_DIR="./run"
mkdir -p "$RUN_DIR"
PID_FILE="${RUN_DIR}/${PROCESS_NAME}.pid"

if [[ -z "$PROCESS_NAME" ]]; then
  echo "❌ Error: Process name is required." >&2
  echo "Usage: $0 <process_name> [start_command]" >&2
  exit 1
fi

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

echo "============================================================"
echo "          PROCESS SUPERVISOR & WATCHDOG                     "
echo "============================================================"
echo "Target Process : $PROCESS_NAME"
echo "PID File Path  : $PID_FILE"
echo "Check Time     : $(timestamp)"
echo "============================================================"

# Check if process is running via pgrep or ps fallback
if command -v pgrep >/dev/null 2>&1; then
  TARGET_PIDS=$(pgrep -f "$PROCESS_NAME" || true)
else
  # Fallback for environments without pgrep (e.g. minimal containers, BSD/Git-Bash)
  TARGET_PIDS=$(ps aux | grep -F "$PROCESS_NAME" | grep -v "grep" | awk '{print $2}' || true)
fi

# Filter out our own script's PID and grep from results
CURRENT_PID=$$
ACTIVE_PIDS=""
for p in $TARGET_PIDS; do
  if [[ "$p" != "$CURRENT_PID" ]]; then
    ACTIVE_PIDS="$ACTIVE_PIDS $p"
  fi
done
ACTIVE_PIDS=$(echo "$ACTIVE_PIDS" | xargs)

if [[ -n "$ACTIVE_PIDS" ]]; then
  echo "✅ Process '$PROCESS_NAME' is ACTIVE and running."
  echo "   Active PID(s): $ACTIVE_PIDS"
  
  # Save primary PID to PID file
  PRIMARY_PID=$(echo "$ACTIVE_PIDS" | awk '{print $1}')
  echo "$PRIMARY_PID" > "$PID_FILE"
  echo "   Saved primary PID to $PID_FILE"

  # Display resource usage for primary PID if ps is available
  echo ""
  echo "--- Process Resource Consumption ---"
  ps -p "$PRIMARY_PID" -o pid,ppid,user,%cpu,%mem,stat,time,comm
  exit 0
else
  echo "⚠️  [ALERT] Process '$PROCESS_NAME' is NOT running!"
  
  # Clean up stale PID file if present
  if [[ -f "$PID_FILE" ]]; then
    echo "   Removing stale PID file ($PID_FILE)..."
    rm -f "$PID_FILE"
  fi

  # Attempt auto-start if a start command was provided
  if [[ -n "$START_COMMAND" ]]; then
    echo "▶️  Attempting to restart '$PROCESS_NAME' via: '$START_COMMAND'"
    eval "$START_COMMAND" &
    NEW_PID=$!
    echo "$NEW_PID" > "$PID_FILE"
    echo "✅ Successfully launched '$PROCESS_NAME' with new PID: $NEW_PID"
    exit 0
  else
    echo "ℹ️  No start command specified. Process remains inactive."
    exit 2
  fi
fi
