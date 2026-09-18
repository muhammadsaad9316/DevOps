#!/bin/bash

# ==============================================================================
# Script: shared_directory_setup.sh
# Track: Linux Fundamentals - Day 13 Drill
# Objective: Provision a shared collaboration folder with SetGID (2775).
# ==============================================================================

SHARED_DIR="./shared_team_workspace"
TEAM_GROUP="devops"

echo "=== Provisioning Collaborative Shared Directory ==="

mkdir -p "$SHARED_DIR"

# Apply permissions: SetGID (2) + rwx for owner (7) + rwx for group (7) + rx for others (5)
chmod 2775 "$SHARED_DIR"

echo "Directory created with SGID permissions:"
ls -ld "$SHARED_DIR"

echo ""
echo "Notice the 's' in the group execute position (drwxrwsr-x)."
echo "Any file subsequently created inside this folder inherits the directory's group."
