#!/bin/bash

# ==============================================================================
# Script: while_counter.sh
# Track: Bash Companion - Day 13
# Objective: Demonstrate while loop counter, incrementing, and early break.
# ==============================================================================

COUNTER=1
TARGET=5
BREAK_AT=4

echo "=== Initiating While Loop Counter (1 to $TARGET) ==="

while [ "$COUNTER" -le "$TARGET" ]; do
  echo "Current iteration: Step #$COUNTER"

  if [ "$COUNTER" -eq "$BREAK_AT" ]; then
    echo "Met designated break condition at $COUNTER. Aborting loop early!"
    break
  fi

  # Increment counter
  ((COUNTER++))
  sleep 0.5
done

echo "Loop exited cleanly."
