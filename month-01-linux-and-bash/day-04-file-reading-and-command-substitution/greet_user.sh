#!/bin/bash

# ==============================================================================
# Script: greet_user.sh
# Track: Bash Companion - Day 04
# Objective: Greet the active user and report host status using command substitution.
# ==============================================================================

CURRENT_USER=$(whoami)
HOST=$(hostname)
UPTIME=$(uptime -p)
KERNEL=$(uname -r)

echo "=================================================="
echo " Welcome back, $CURRENT_USER!"
echo " Connected Host : $HOST"
echo " Kernel Release : $KERNEL"
echo " Host Uptime    : $UPTIME"
echo "=================================================="
