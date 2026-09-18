#!/bin/bash

# ==============================================================================
# Script: timestamp_backup.sh
# Track: Bash Companion - Day 04
# Objective: Build timestamped filenames using command substitution $(date).
# ==============================================================================

# 1. Capture current date and time in standardized ISO-like format
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 2. Define backup folder and filename
BACKUP_DIR="./backups"
BACKUP_FILE="${BACKUP_DIR}/system_state_${TIMESTAMP}.tar.gz"

echo "Current Timestamp captured: $TIMESTAMP"

# 3. Create destination directory
mkdir -p "$BACKUP_DIR"

# 4. Simulate backup creation
touch "$BACKUP_FILE"

echo "Generated timestamped backup artifact:"
ls -lh "$BACKUP_FILE"
