#!/bin/bash

# ==============================================================================
# Script: create_folder.sh
# Track: Bash Companion - Day 03
# Objective: Demonstrate variable declaration and dynamic directory creation.
# ==============================================================================

# 1. Declare target directory name variable (no spaces around '=')
TARGET_DIR="devops_daily_backups"
SUB_DIR="logs_archive"

# 2. Print intention to user
echo "Initiating setup for target directory: $TARGET_DIR"

# 3. Create nested directory using the variable with quotes to handle spaces safely
mkdir -p "$TARGET_DIR/$SUB_DIR"

# 4. Populate with a confirmation file
touch "$TARGET_DIR/$SUB_DIR/.initialized"

# 5. Confirm result
echo "Successfully provisioned directory path: $TARGET_DIR/$SUB_DIR"
ls -ld "$TARGET_DIR/$SUB_DIR"
