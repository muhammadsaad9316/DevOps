#!/bin/bash

# ==============================================================================
# Script: batch_rename.sh
# Track: Bash Companion - Day 11
# Objective: Loop through directory files and safely apply a suffix.
#
# Usage: ./batch_rename.sh [target_directory] [extension_to_match] [suffix_to_add]
# ==============================================================================

WORK_DIR="${1:-./test_folder}"
EXT="${2:-txt}"
SUFFIX="${3:-bak}"

# Provision sandbox environment for safe dry-run
mkdir -p "$WORK_DIR"
touch "$WORK_DIR/report1.$EXT" "$WORK_DIR/report2.$EXT" "$WORK_DIR/notes.$EXT"

echo "=== Performing Batch Rename in $WORK_DIR ==="
for FILE in "$WORK_DIR"/*."$EXT"; do
  # Skip if no matches
  [ -f "$FILE" ] || continue

  NEW_NAME="${FILE}.${SUFFIX}"
  echo "Renaming: $(basename "$FILE") -> $(basename "$NEW_NAME")"
  mv "$FILE" "$NEW_NAME"
done

echo "Updated Directory Contents:"
ls -la "$WORK_DIR"
