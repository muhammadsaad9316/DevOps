#!/bin/bash

# ==============================================================================
# Script: guard_clause_demo.sh
# Track: Bash Companion - Day 08
# Objective: Implement early-exit guard clauses to guarantee required arguments.
#
# Usage: ./guard_clause_demo.sh <service_name>
# ==============================================================================

# GUARD CLAUSE: Verify argument count ($#) is non-zero
if [ "$#" -eq 0 ]; then
  echo "Error: Missing required argument!" >&2
  echo "Usage: $0 <service_name>" >&2
  exit 1
fi

SERVICE="$1"

echo "Passed guard clause validation."
echo "Performing health assessment on service: $SERVICE"
echo "Service is configured and operational."
exit 0
