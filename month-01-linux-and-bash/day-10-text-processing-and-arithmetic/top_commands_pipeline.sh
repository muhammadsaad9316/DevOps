#!/bin/bash

# ==============================================================================
# Script: top_commands_pipeline.sh
# Track: Linux Fundamentals - Day 10 Drill
# Objective: Pipeline isolating top 10 most common commands in shell history.
# ==============================================================================

HISTFILE_PATH="${HISTFILE:-$HOME/.bash_history}"

if [ ! -r "$HISTFILE_PATH" ]; then
  echo "Notice: Cannot read history directly from $HISTFILE_PATH."
  echo "Simulating top command breakdown..."
  cat << 'EOF' | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
ls -la
cd /var/log
ls -lh
git status
docker ps
kubectl get pods
ls
git status
cd ~
git status
kubectl get pods
EOF
  exit 0
fi

echo "=== Top 10 Most Frequently Executed Commands ==="
cat "$HISTFILE_PATH" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 10
