#!/bin/bash

# ==============================================================================
# Script: rebuild_tree.sh
# Track: Linux Fundamentals - Day 03 Drill
# Objective: Rebuild a 5-level directory structure from memory.
# ==============================================================================

BASE="prod_app"

echo "Building 5-tier architecture directory tree under ./$BASE..."

# Create 5 levels with mkdir -p
mkdir -p "$BASE/tier1_edge/tier2_lb/tier3_app/tier4_service/tier5_db"

# Populate each level with configuration or marker files
touch "$BASE/tier1_edge/cloudflare.conf"
touch "$BASE/tier2_lb/nginx.conf"
touch "$BASE/tier3_app/app.py"
touch "$BASE/tier4_service/cache.sock"
touch "$BASE/tier5_db/schema.sql"

echo "Structure successfully constructed:"
which tree >/dev/null 2>&1 && tree "$BASE" || ls -R "$BASE"
