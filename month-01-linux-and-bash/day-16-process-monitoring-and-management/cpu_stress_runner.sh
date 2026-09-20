#!/usr/bin/env bash

# ==============================================================================
# Script: cpu_stress_runner.sh
# Track: Bash Companion - Day 16
# Objective: Controlled workload simulation script for process monitoring:
#            1. Reports its own PID ($$) and parent PPID
#            2. Implements POSIX signal traps (SIGTERM, SIGINT) for graceful exit
#            3. Simulates active CPU work for testing top, htop, and watchdog
#
# Usage: ./cpu_stress_runner.sh [duration_seconds]
# ==============================================================================

set -euo pipefail

DURATION="${1:-60}"
SCRIPT_PID=$$
PARENT_PID=$PPID

cleanup() {
  echo ""
  echo "🛑 Signal received! Initiating graceful shutdown sequence..."
  echo "Flushing simulated buffers and closing worker handles..."
  sleep 0.5
  echo "✅ Process PID $SCRIPT_PID cleanly terminated."
  exit 0
}

# Trap termination and interrupt signals
trap cleanup SIGINT SIGTERM SIGHUP

echo "============================================================"
echo "          CPU STRESS & SIGNAL HANDLING RUNNER               "
echo "============================================================"
echo "Process PID       : $SCRIPT_PID"
echo "Parent PID (PPID) : $PARENT_PID"
echo "Target Duration   : $DURATION seconds"
echo "Active Traps      : SIGINT (2), SIGTERM (15), SIGHUP (1)"
echo "============================================================"
echo "💡 Test terminating this process from another terminal via:"
echo "   kill -15 $SCRIPT_PID   (Graceful termination)"
echo "============================================================"

START_TIME=$(date +%s)

# Controlled loop simulating processing
counter=0
while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  
  if [[ "$ELAPSED" -ge "$DURATION" ]]; then
    echo "⏱️  Execution time limit of ${DURATION}s reached."
    break
  fi

  # Compute arithmetic work
  counter=$((counter + 1))
  
  # Heartbeat every 5 seconds
  if (( counter % 50000 == 0 )); then
    echo "[PID: $SCRIPT_PID] Still alive... (${ELAPSED}s elapsed, iterations: $counter)"
  fi
done

cleanup
