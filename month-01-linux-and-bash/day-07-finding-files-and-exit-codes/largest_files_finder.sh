#!/bin/bash

# ==============================================================================
# Script: largest_files_finder.sh
# Track: Linux Fundamentals - Day 07 Challenge
# Objective: Find and display the top N largest files in a given directory path.
#
# Usage: ./largest_files_finder.sh [directory_path] [count]
# ==============================================================================

TARGET_DIR="${1:-/var}"
TOP_N="${2:-5}"

echo "Scanning for the top $TOP_N largest files in: $TARGET_DIR"
echo "------------------------------------------------------------"

# Execute find safely suppressing permission errors
find "$TARGET_DIR" -type f -exec ls -lh {} + 2>/dev/null | \
  sort -k5 -rh | \
  head -n "$TOP_N" | \
  awk '{printf "%-10s %-8s %-8s %s\n", $5, $3, $4, $9}'

echo "------------------------------------------------------------"
echo "Scan complete."
