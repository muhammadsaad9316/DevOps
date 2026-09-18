#!/bin/bash

# ==============================================================================
# Script: shebang_demo.sh
# Track: Bash Companion - Day 02
# Objective: Demonstrate shebang interpretation and direct binary execution.
#
# Instructions:
# 1. Grant execute permissions: chmod +x shebang_demo.sh
# 2. Execute directly:        ./shebang_demo.sh
# ==============================================================================

echo "Current Shell Interpreter: $SHELL"
echo "Executed via Shebang: #!/bin/bash"
echo "Working directory where script was called: $(pwd)"
