#!/bin/bash

# ==============================================================================
# Script: read_lines_safely.sh
# Track: Bash Companion - Day 13
# Objective: Read text file line-by-line numbered, preserving spacing and backslashes.
#
# Usage: ./read_lines_safely.sh [file_path]
# ==============================================================================

FILE_PATH="${1:-/etc/hosts}"

if [ ! -r "$FILE_PATH" ]; then
  echo "Error: Cannot read source file '$FILE_PATH'." >&2
  exit 1
fi

echo "=== Reading File: $FILE_PATH (Line-by-Line) ==="

line_num=1
# IFS= prevents trimming leading/trailing whitespace
# -r prevents backslashes from acting as escape characters
# || [ -n "$line" ] ensures the final line without a trailing newline is processed
while IFS= read -r line || [ -n "$line" ]; do
  printf "[%02d] %s\n" "$line_num" "$line"
  ((line_num++))
done < "$FILE_PATH"

echo "=== End of File ==="
