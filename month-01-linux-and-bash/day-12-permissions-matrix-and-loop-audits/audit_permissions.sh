#!/bin/bash

# ==============================================================================
# Script: audit_permissions.sh
# Track: Bash Companion - Day 12
# Objective: Loop through directory files and print each with its permission string.
#
# Usage: ./audit_permissions.sh [directory_path]
# ==============================================================================

TARGET_DIR="${1:-.}"

echo "=== Auditing File Permissions in: $TARGET_DIR ==="
printf "%-12s %-10s %-10s %s\n" "PERMISSIONS" "OWNER" "GROUP" "NAME"
echo "------------------------------------------------------------"

for ITEM in "$TARGET_DIR"/*; do
  [ -e "$ITEM" ] || continue
  # Extract long listing fields using stat or ls
  PERMS=$(ls -ld "$ITEM" | awk '{print $1}')
  OWNER=$(ls -ld "$ITEM" | awk '{print $3}')
  GROUP=$(ls -ld "$ITEM" | awk '{print $4}')
  NAME=$(basename "$ITEM")

  printf "%-12s %-10s %-10s %s\n" "$PERMS" "$OWNER" "$GROUP" "$NAME"
done

echo "------------------------------------------------------------"
echo "Audit completed."
