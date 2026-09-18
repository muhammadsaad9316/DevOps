#!/bin/bash

# ==============================================================================
# Script: interactive_menu.sh
# Track: Bash Companion - Day 14
# Objective: Interactive terminal management menu using 'case' and default fallback.
# ==============================================================================

echo "=========================================="
echo "    DEVOPS OPERATOR UTILITY MENU          "
echo "=========================================="
echo "  1) Display Active System Uptime"
echo "  2) Check Disk Usage on Root Partition"
echo "  3) Show Top 5 Memory-Consuming Processes"
echo "  4) Exit Utility"
echo "=========================================="
read -p "Select an option [1-4]: " USER_CHOICE

case "$USER_CHOICE" in
  1)
    echo "--- System Uptime ---"
    uptime
    ;;
  2)
    echo "--- Root Disk Utilization ---"
    df -h /
    ;;
  3)
    echo "--- Top 5 Memory Processes ---"
    ps aux --sort=-%mem | head -n 6
    ;;
  4)
    echo "Exiting operator utility. Goodbye!"
    exit 0
    ;;
  *)
    echo "⚠️  Invalid selection '$USER_CHOICE'. Please choose between 1 and 4." >&2
    exit 1
    ;;
esac
