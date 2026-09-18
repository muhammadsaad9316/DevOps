#!/bin/bash

# ==============================================================================
# Script: greet_interactive.sh
# Track: Bash Companion - Day 05
# Objective: Interactive input gathering using 'read -p'.
# ==============================================================================

# Prompt user directly with custom text on the same line
read -p "Please enter your operator username: " OPERATOR_NAME
read -p "Enter current project assignment: " PROJECT_NAME

echo ""
echo "=== Session Initialized ==="
echo "Operator: $OPERATOR_NAME"
echo "Project : $PROJECT_NAME"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Welcome aboard! Let's automate infrastructure."
