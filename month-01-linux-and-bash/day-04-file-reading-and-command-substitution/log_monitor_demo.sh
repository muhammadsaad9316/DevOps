#!/bin/bash

# ==============================================================================
# Script: log_monitor_demo.sh
# Track: Linux Fundamentals - Day 04 Drill
# Objective: Generate live log events to test 'tail -f'.
# ==============================================================================

LOG_FILE="simulated_app.log"
echo "=== Starting background logger to $LOG_FILE ==="
echo "In another terminal, run: tail -f $LOG_FILE"
echo "Press Ctrl+C to terminate this generator."

count=1
while true; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Event #$count: Application health check healthy." >> "$LOG_FILE"
  ((count++))
  sleep 2
done
