#!/bin/bash

# ==============================================================================
# Script: storage_triage_analyzer.sh
# Track: Bash Companion - Day 21 (Disk and Space Scripts)
# Objective: Task b21-biggest: Print the 5 largest folders in a given path.
#
# Usage:
#   ./storage_triage_analyzer.sh [DIRECTORY_PATH]
#
# Examples:
#   ./storage_triage_analyzer.sh             # Scan current folder
#   ./storage_triage_analyzer.sh /var/log    # Scan /var/log
# ==============================================================================

TARGET_DIR="${1:-.}"

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

echo "Scanning the 5 largest folders in: $TARGET_DIR"
echo "--------------------------------------------------"

# du -h        : Display sizes in human-readable format (K, M, G)
# --max-depth=1: Look only at immediate subfolders
# sort -hr     : Sort numbers in reverse (largest first)
# head -n 6    : Take top 5 subfolders (ignoring the total line)

du -h --max-depth=1 "$TARGET_DIR" 2>/dev/null | sort -hr | head -n 6

echo "--------------------------------------------------"
echo "Scan complete."
