#!/bin/bash

# ==============================================================================
# Script: check_file_exists.sh
# Track: Bash Companion - Day 08
# Objective: Check if a file exists before modifying it, with an else branch.
#
# Usage: ./check_file_exists.sh <filename>
# ==============================================================================

FILE_PATH="${1:-test_target.txt}"

echo "Checking status for: $FILE_PATH"

if [ -f "$FILE_PATH" ]; then
  echo "File '$FILE_PATH' exists."
  echo "Current line count: $(wc -l < "$FILE_PATH")"
else
  echo "File '$FILE_PATH' does NOT exist."
  echo "Creating file safely now..."
  touch "$FILE_PATH"
  echo "Initialized on $(date)" > "$FILE_PATH"
  echo "File created successfully."
fi
