#!/bin/bash

# ==============================================================================
# Script: find_writable.sh
# Track: Bash Companion - Day 12
# Objective: List files in a folder that are writable by the current executing user.
#
# Usage: ./find_writable.sh [directory_path]
# ==============================================================================

TARGET_DIR="${1:-.}"
CURRENT_USER=$(whoami)

echo "Auditing writable resources for user: [$CURRENT_USER] in $TARGET_DIR"
echo "------------------------------------------------------------"

writable_found=0
for FILE in "$TARGET_DIR"/*; do
  [ -e "$FILE" ] || continue
  # Bash test operator -w checks write permission for the executing user
  if [ -w "$FILE" ]; then
    echo " [WRITABLE] $FILE"
    ((writable_found++))
  fi
done

echo "------------------------------------------------------------"
echo "Total writable files identified: $writable_found"
