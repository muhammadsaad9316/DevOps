#!/bin/bash

# ==============================================================================
# Script: variable_quotes_demo.sh
# Track: Bash Companion - Day 03
# Objective: Prove the distinction between single quotes and double quotes.
# ==============================================================================

# Three variables
SERVER_ROLE="Database"
INSTANCE_ID="i-094382abcedf"
MAX_CONNECTIONS=500

echo "=== Double Quotes (Variable Expansion) ==="
echo "Role: $SERVER_ROLE"
echo "Instance: $INSTANCE_ID"
echo "Config line: max_conn=$MAX_CONNECTIONS"

echo ""
echo "=== Single Quotes (Literal Characters) ==="
echo 'Role: $SERVER_ROLE'
echo 'Instance: $INSTANCE_ID'
echo 'Config line: max_conn=$MAX_CONNECTIONS'

echo ""
echo "Notice: In single quotes, the variable name is printed literally, not its value."
