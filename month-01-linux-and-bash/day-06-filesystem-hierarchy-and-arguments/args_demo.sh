#!/bin/bash

# ==============================================================================
# Script: args_demo.sh
# Track: Bash Companion - Day 06
# Objective: Demonstrate CLI positional arguments and count tracking.
#
# Usage: ./args_demo.sh first_arg second_arg third_arg
# ==============================================================================

echo "Script binary name (\$0)     : $0"
echo "First argument      (\$1)     : $1"
echo "Second argument     (\$2)     : $2"
echo "Total arguments count (\$#)   : $#"
echo "All arguments as list (\$@)   : $@"

echo ""
echo "Evaluating argument count..."
if [ "$#" -lt 2 ]; then
  echo "Notice: Less than two arguments supplied. Try passing more arguments!"
else
  echo "Success: Received $# arguments."
fi
