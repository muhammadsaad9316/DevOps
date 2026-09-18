#!/bin/bash

# ==============================================================================
# Script: test_conditions.sh
# Track: Bash Companion - Day 09
# Objective: Demonstrate file test flags (-f, -d, -r, -s) and string operators.
# ==============================================================================

TEST_FILE="/etc/hosts"
TEST_DIR="/etc"
ENV_MODE="staging"

echo "=== 1. File & Directory Tests ==="
if [ -f "$TEST_FILE" ]; then
  echo "[PASS] '$TEST_FILE' is a valid regular file."
fi

if [ -d "$TEST_DIR" ]; then
  echo "[PASS] '$TEST_DIR' is an existing directory."
fi

if [ -r "$TEST_FILE" ]; then
  echo "[PASS] '$TEST_FILE' has read permissions granted."
fi

if [ -s "$TEST_FILE" ]; then
  echo "[PASS] '$TEST_FILE' is non-empty (size > 0 bytes)."
fi

echo ""
echo "=== 2. String Comparison Tests ==="
if [ "$ENV_MODE" = "staging" ]; then
  echo "[MATCH] Environment matches target 'staging'."
fi

if [ "$ENV_MODE" != "production" ]; then
  echo "[SAFE] Current mode is NOT production; mock deployment permitted."
fi
