#!/bin/bash

# ==============================================================================
# Script: backup_manager.sh
# Track: Bash Companion - Day 22 (A Real Backup Script)
# Objectives:
#   - b22-check-source: Validate source directory exists before running
#   - b22-tar-script: Compress folder into a timestamped .tar.gz archive
#   - b22-keep-recent: Delete old archives exceeding retention days (default: 7)
#
# Usage:
#   ./backup_manager.sh <SOURCE_DIR> [BACKUP_DEST_DIR] [RETENTION_DAYS]
#
# Examples:
#   ./backup_manager.sh ./my-data                    # Backup to ./backups (7-day retention)
#   ./backup_manager.sh /var/log /mnt/backups 14     # Backup /var/log with 14-day retention
# ==============================================================================

SOURCE_DIR="$1"
BACKUP_DEST_DIR="${2:-./backups}"
RETENTION_DAYS="${3:-7}"

# Task b22-check-source: Verify source folder argument and existence
if [ -z "$SOURCE_DIR" ]; then
    echo "Error: Missing source directory argument."
    echo "Usage: $0 <SOURCE_DIR> [BACKUP_DEST_DIR] [RETENTION_DAYS]"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Ensure backup destination directory exists
mkdir -p "$BACKUP_DEST_DIR"

# Generate timestamp and archive name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SOURCE_BASE=$(basename "$SOURCE_DIR")
ARCHIVE_NAME="${SOURCE_BASE}_backup_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_DEST_DIR}/${ARCHIVE_NAME}"

echo "=========================================="
echo " Starting Automated Backup"
echo "=========================================="
echo "Source:      $SOURCE_DIR"
echo "Destination: $ARCHIVE_PATH"
echo "Retention:   $RETENTION_DAYS days"
echo "------------------------------------------"

# Task b22-tar-script: Create compressed tar archive
echo "Creating compressed archive..."
# Using -C to package without long parent directory paths
PARENT_DIR=$(dirname "$SOURCE_DIR")
tar -czf "$ARCHIVE_PATH" -C "$PARENT_DIR" "$SOURCE_BASE"

if [ $? -ne 0 ]; then
    echo "Error: Backup archive creation failed."
    exit 1
fi

# Check and display archive size
ARCHIVE_SIZE=$(ls -lh "$ARCHIVE_PATH" | awk '{print $5}')
echo "SUCCESS: Archive created: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
echo "------------------------------------------"

# Task b22-keep-recent: Remove archives older than RETENTION_DAYS
echo "Pruning archives older than $RETENTION_DAYS days in $BACKUP_DEST_DIR..."
PRUNED_COUNT=0

while IFS= read -r old_backup; do
    if [ -n "$old_backup" ]; then
        echo "Deleting old archive: $(basename "$old_backup")"
        rm -f "$old_backup"
        PRUNED_COUNT=$((PRUNED_COUNT + 1))
    fi
done < <(find "$BACKUP_DEST_DIR" -maxdepth 1 -name "${SOURCE_BASE}_backup_*.tar.gz" -type f -mtime +"$RETENTION_DAYS")

echo "Pruning complete. Removed $PRUNED_COUNT expired archive(s)."
echo "=========================================="
echo " Backup finished successfully."
echo "=========================================="

exit 0
