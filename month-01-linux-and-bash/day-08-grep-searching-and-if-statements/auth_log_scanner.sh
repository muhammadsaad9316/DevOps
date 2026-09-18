#!/bin/bash

# ==============================================================================
# Script: auth_log_scanner.sh
# Track: Linux Fundamentals - Day 08 Drill
# Objective: Scan auth logs for failed login attempts and summarize statistics.
# ==============================================================================

LOG_PATH="/var/log/auth.log"

if [ ! -r "$LOG_PATH" ]; then
  echo "Notice: Cannot read $LOG_PATH directly (requires root privileges)."
  echo "Attempting read using sudo or fallback..."
  CMD="sudo grep"
else
  CMD="grep"
fi

echo "Scanning for failed login attempts in $LOG_PATH..."
$CMD -i "Failed password" "$LOG_PATH" 2>/dev/null | tail -n 5

FAIL_COUNT=$($CMD -ic "Failed password" "$LOG_PATH" 2>/dev/null || echo 0)
echo ""
echo "Total detected failed login events: $FAIL_COUNT"
