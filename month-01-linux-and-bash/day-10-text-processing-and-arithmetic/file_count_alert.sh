#!/bin/bash

# ==============================================================================
# Script: file_count_alert.sh
# Track: Bash Companion - Day 10
# Objective: Count files in a folder and trigger an alert if count > threshold.
#
# Usage: ./file_count_alert.sh [directory] [threshold]
# ==============================================================================

TARGET_DIR="${1:-.}"
THRESHOLD="${2:-10}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' does not exist." >&2
  exit 1
fi

# Count files non-recursively (excluding directories)
FILE_COUNT=$(find "$TARGET_DIR" -maxdepth 1 -type f | wc -l)

echo "Directory Monitored: $TARGET_DIR"
echo "Threshold Limit    : $THRESHOLD"
echo "Total Files Found  : $FILE_COUNT"

if [ "$FILE_COUNT" -gt "$THRESHOLD" ]; then
  echo "⚠️  [ALERT]: File count ($FILE_COUNT) exceeds allowable threshold ($THRESHOLD)!"
  exit 2
else
  echo "✅ [HEALTHY]: File count is within acceptable operational limits."
  exit 0
fi
