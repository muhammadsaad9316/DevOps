#!/bin/bash

# ==============================================================================
# Script: disk_space_sentinel.sh
# Track: Bash Companion - Day 21 (Disk and Space Scripts)
# Objective: Check disk usage percentage and warn if it exceeds a threshold.
#
# Usage:
#   ./disk_space_sentinel.sh [THRESHOLD] [MOUNT_POINT]
#   ./disk_space_sentinel.sh --percent-only [MOUNT_POINT]
#
# Examples:
#   ./disk_space_sentinel.sh                     # Check / with default 80% threshold
#   ./disk_space_sentinel.sh 85 /home            # Warn if /home is above 85%
#   ./disk_space_sentinel.sh --percent-only      # Prints percentage number only: 45
# ==============================================================================

# Task b21-disk-check: Print disk usage as a percentage number only
if [ "$1" = "--percent-only" ] || [ "$1" = "-p" ]; then
    TARGET="${2:-/}"
    USAGE=$(df "$TARGET" | awk 'NR==2 {print $(NF-1)}' | tr -d '%')
    echo "$USAGE"
    exit 0
fi

# Set threshold (default 80%) and mount point (default /)
THRESHOLD="${1:-80}"
MOUNT_POINT="${2:-/}"

# Get current usage percentage
USAGE=$(df "$MOUNT_POINT" | awk 'NR==2 {print $(NF-1)}' | tr -d '%')

echo "Checking disk usage for: $MOUNT_POINT"
echo "Current Usage: ${USAGE}%"
echo "Threshold:     ${THRESHOLD}%"

# Task b21-warn-full: Warn when usage passes the threshold
if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: Disk usage is too high! (${USAGE}% >= ${THRESHOLD}%)"
    echo "Please free up disk space."
    exit 1
else
    echo "OK: Disk space is within safe limits (${USAGE}% < ${THRESHOLD}%)."
    exit 0
fi
