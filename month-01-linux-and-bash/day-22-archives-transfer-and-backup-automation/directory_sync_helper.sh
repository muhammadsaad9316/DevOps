#!/bin/bash

# ==============================================================================
# Script: directory_sync_helper.sh
# Track: Linux Fundamentals - Day 22 (Copying Between Machines & Folders)
# Objectives:
#   - d22-rsync: Sync folders using rsync, observing delta-only transfer
#   - Provide safe dry-run mode and handle trailing slash nuances
#
# Usage:
#   ./directory_sync_helper.sh <SOURCE_PATH> <TARGET_PATH> [--dry-run] [--delete]
#
# Examples:
#   ./directory_sync_helper.sh ./src ./dest --dry-run
#   ./directory_sync_helper.sh ./src ./dest
#   ./directory_sync_helper.sh ./src user@remote-host:/backup/dest
# ==============================================================================

SOURCE_PATH="$1"
TARGET_PATH="$2"
DRY_RUN=false
DELETE_FLAG=false

# Validate arguments
if [ -z "$SOURCE_PATH" ] || [ -z "$TARGET_PATH" ]; then
    echo "Error: Source and target paths are required."
    echo "Usage: $0 <SOURCE_PATH> <TARGET_PATH> [--dry-run] [--delete]"
    exit 1
fi

# Parse optional flags
for arg in "${@:3}"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        --delete)
            DELETE_FLAG=true
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# Check if rsync is installed
if ! command -v rsync &>/dev/null; then
    echo "Error: 'rsync' command not found. Please install rsync."
    exit 1
fi

echo "=========================================="
echo " Directory Synchronization"
echo "=========================================="
echo "Source:      $SOURCE_PATH"
echo "Target:      $TARGET_PATH"
echo "Dry Run:     $DRY_RUN"
echo "Delete Old:  $DELETE_FLAG"
echo "------------------------------------------"

# Build rsync options:
# -a: archive mode (preserves permissions, owners, symlinks, timestamps)
# -v: verbose output
# -z: compress file data during transfer
# -h: human-readable numbers
# --stats: display transfer summary metrics
RSYNC_OPTS="-avzh --stats"

if [ "$DRY_RUN" = true ]; then
    RSYNC_OPTS="$RSYNC_OPTS --dry-run"
    echo "[INFO] Running in DRY-RUN mode (no files will actually be modified)."
fi

if [ "$DELETE_FLAG" = true ]; then
    RSYNC_OPTS="$RSYNC_OPTS --delete"
    echo "[WARN] Mirror mode enabled: files deleted from source will be removed from target."
fi

# Execute rsync
# Note: rsync treats 'source/' and 'source' differently:
#   'source/' copies directory contents into target
#   'source'  creates a folder named 'source' inside target
rsync $RSYNC_OPTS "$SOURCE_PATH" "$TARGET_PATH"

if [ $? -eq 0 ]; then
    echo "------------------------------------------"
    echo "Sync operation completed successfully."
    echo "=========================================="
    exit 0
else
    echo "------------------------------------------"
    echo "Error: Sync operation failed with exit code $?."
    echo "=========================================="
    exit 1
fi
