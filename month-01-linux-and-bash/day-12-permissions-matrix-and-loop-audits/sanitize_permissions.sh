#!/bin/bash

# ==============================================================================
# Script: sanitize_permissions.sh
# Track: Bash Companion - Day 12
# Objective: Enforce security hardening (644 on files, 755 on directories).
#
# Usage: ./sanitize_permissions.sh [directory_path]
# ==============================================================================

TARGET_DIR="${1:-./sandbox_folder}"

# Provision test sandbox if none exists
mkdir -p "$TARGET_DIR/subdir"
touch "$TARGET_DIR/config1.json" "$TARGET_DIR/subdir/settings.yaml"

echo "=== Sanitizing Permissions in: $TARGET_DIR ==="

for ITEM in "$TARGET_DIR"/*; do
  [ -e "$ITEM" ] || continue

  if [ -f "$ITEM" ]; then
    echo "Enforcing 644 on file: $(basename "$ITEM")"
    chmod 644 "$ITEM"
  elif [ -d "$ITEM" ]; then
    echo "Enforcing 755 on directory: $(basename "$ITEM")"
    chmod 755 "$ITEM"
  fi
done

echo "Sanitization complete."
ls -la "$TARGET_DIR"
