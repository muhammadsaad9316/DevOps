#!/bin/bash

# ==============================================================================
# Script: make_folder_arg.sh
# Track: Bash Companion - Day 06
# Objective: Create directories dynamically based on positional CLI arguments.
#
# Usage: ./make_folder_arg.sh <folder_name>
# ==============================================================================

TARGET_DIR="$1"

# Guard check: Ensure argument exists
if [ -z "$TARGET_DIR" ]; then
  echo "Error: Missing argument."
  echo "Usage: $0 <directory_name>"
  exit 1
fi

echo "Creating requested directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

if [ -d "$TARGET_DIR" ]; then
  echo "Directory successfully verified: $(pwd)/$TARGET_DIR"
else
  echo "Failed to create directory $TARGET_DIR"
  exit 1
fi
