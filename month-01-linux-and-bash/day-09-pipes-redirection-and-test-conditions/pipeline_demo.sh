#!/bin/bash

# ==============================================================================
# Script: pipeline_demo.sh
# Track: Linux Fundamentals - Day 09 Drill
# Objective: Demonstrate pipelines, tee, and stdout/stderr separation.
# ==============================================================================

LOG_FILE="pipeline_audit.log"
ERR_FILE="pipeline_errors.log"

echo "=== Chaining Pipelines & Logging with Tee ==="

# Chain ls | grep | wc and pipe simultaneously to screen and file
echo -n "Total .conf files located in /etc: "
ls /etc 2>"$ERR_FILE" | grep '\.conf$' | tee "$LOG_FILE" | wc -l

echo ""
echo "Files logged in $LOG_FILE (First 3 entries):"
head -n 3 "$LOG_FILE"

echo ""
echo "Errors logged in $ERR_FILE: $(wc -l < "$ERR_FILE") errors."
