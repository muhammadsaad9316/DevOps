#!/bin/bash

# ==============================================================================
# Script: arithmetic_demo.sh
# Track: Bash Companion - Day 10
# Objective: Demonstrate integer math evaluation $(( ... )) and comparisons.
# ==============================================================================

A=25
B=10

echo "Initial Values: A=$A, B=$B"
echo "Addition (A + B)        : $(( A + B ))"
echo "Subtraction (A - B)     : $(( A - B ))"
echo "Multiplication (A * B)  : $(( A * B ))"
echo "Division (A / B)        : $(( A / B ))  (Integer division truncates decimals)"
echo "Modulo Remainder (A % B): $(( A % B ))"

echo ""
echo "=== Numeric Comparisons ==="
if [ "$A" -gt "$B" ]; then
  echo "Validation: $A is greater than $B (-gt)"
fi

if [ "$B" -lt "$A" ]; then
  echo "Validation: $B is less than $A (-lt)"
fi

if [ "$(( A % 5 ))" -eq 0 ]; then
  echo "Validation: $A is evenly divisible by 5 (-eq 0)"
fi
