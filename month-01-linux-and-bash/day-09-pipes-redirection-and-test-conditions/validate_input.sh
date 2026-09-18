#!/bin/bash

# ==============================================================================
# Script: validate_input.sh
# Track: Bash Companion - Day 09
# Objective: Check if variables are empty (-z) or non-empty (-n).
#
# Usage: ./validate_input.sh [optional_value]
# ==============================================================================

INPUT_VAL="$1"

echo "=== Evaluating String Emptiness ==="

if [ -z "$INPUT_VAL" ]; then
  echo "Notice: \$1 is empty (length is zero via -z)."
  echo "Assigning default fallback value: 'default_cluster_01'"
  INPUT_VAL="default_cluster_01"
fi

if [ -n "$INPUT_VAL" ]; then
  echo "Confirmed: Variable is populated (non-zero length via -n): $INPUT_VAL"
fi
