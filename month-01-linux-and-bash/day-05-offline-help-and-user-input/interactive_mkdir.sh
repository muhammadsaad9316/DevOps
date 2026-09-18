#!/bin/bash

# ==============================================================================
# Script: interactive_mkdir.sh
# Track: Bash Companion - Day 05
# Objective: Request folder name from user, validate, and create it.
# ==============================================================================

echo "=== Dynamic Directory Creator ==="
read -p "Enter desired directory name to create: " NEW_DIR

# Guard against empty input
if [ -z "$NEW_DIR" ]; then
  echo "Error: Directory name cannot be empty."
  exit 1
fi

echo "Creating directory: $NEW_DIR"
mkdir -p "$NEW_DIR"
touch "$NEW_DIR/README.md"
echo "# $NEW_DIR" > "$NEW_DIR/README.md"

echo "Directory created successfully at: $(pwd)/$NEW_DIR"
ls -la "$NEW_DIR"
