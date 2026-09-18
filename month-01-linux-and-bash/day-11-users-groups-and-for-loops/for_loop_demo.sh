#!/bin/bash

# ==============================================================================
# Script: for_loop_demo.sh
# Track: Bash Companion - Day 11
# Objective: Demonstrate for loop syntax over lists, numeric ranges, and globs.
# ==============================================================================

echo "=== 1. Iterating Over an Explicit List ==="
for ENV in development staging qa production; do
  echo "Deploying microservice configuration to target environment: [$ENV]"
done

echo ""
echo "=== 2. Iterating Over a Numeric Range ==="
for SERVER_ID in {1..5}; do
  echo "Pinging cluster worker-node-0$SERVER_ID..."
done

echo ""
echo "=== 3. Iterating Over Files in a Directory ==="
for CONF in /etc/*.conf; do
  # Check if glob actually matched any files
  [ -e "$CONF" ] || continue
  echo "Discovered configuration: $(basename "$CONF")"
  # Limit output to first 5 for brevity
  ((count++))
  [ "$count" -ge 5 ] && break
done
