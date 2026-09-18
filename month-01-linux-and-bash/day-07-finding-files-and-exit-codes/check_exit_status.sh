#!/bin/bash

# ==============================================================================
# Script: check_exit_status.sh
# Track: Bash Companion - Day 07
# Objective: Demonstrate exit status inspection ($?) and explicit termination codes.
# ==============================================================================

echo "=== 1. Testing Successful Command ==="
ls /etc/hosts >/dev/null 2>&1
STATUS=$?
echo "Command 'ls /etc/hosts' exited with status: $STATUS (0 indicates Success)"

echo ""
echo "=== 2. Testing Non-Existent Command ==="
cat /path/to/nonexistent_file_xyz 2>/dev/null
STATUS=$?
echo "Command exited with status: $STATUS (Non-zero indicates Failure)"

echo ""
echo "=== 3. Simulating Guarded Failure Exit ==="
if [ "$STATUS" -ne 0 ]; then
  echo "Encountered expected failure. Exiting script with custom error code 42."
  exit 42
fi
