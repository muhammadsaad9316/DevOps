#!/usr/bin/env bash

# ==============================================================================
# Script: ssh_key_auditor.sh
# Track: Bash Companion - Day 15
# Objective: Audit OpenSSH client & server file permissions against StrictModes.
#            Identifies over-permissive files and optionally enforces hardening.
#
# Usage: ./ssh_key_auditor.sh [--fix] [ssh_directory]
# ==============================================================================

set -euo pipefail

AUTO_FIX=false
if [[ "${1:-}" == "--fix" ]]; then
  AUTO_FIX=true
  shift
fi

TARGET_DIR="${1:-$HOME/.ssh}"

echo "============================================================"
echo "          SSH SECURITY & PERMISSIONS AUDITOR                "
echo "============================================================"
echo "Target Directory : $TARGET_DIR"
echo "Auto-Fix Enabled : $AUTO_FIX"
echo "============================================================"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "⚠️  SSH directory '$TARGET_DIR' does not exist."
  echo "Creating directory with standard 700 permissions..."
  mkdir -p "$TARGET_DIR"
  chmod 700 "$TARGET_DIR"
  echo "✅ Created $TARGET_DIR (Mode: 700)"
  exit 0
fi

# Function to get octal permissions
get_octal_perms() {
  local path="$1"
  # Works on Linux (GNU stat) and macOS (BSD stat)
  if stat --version >/dev/null 2>&1; then
    stat -c "%a" "$path"
  else
    stat -f "%OLp" "$path"
  fi
}

DIR_PERMS=$(get_octal_perms "$TARGET_DIR")
if [[ "$DIR_PERMS" -ne 700 ]]; then
  echo "❌ [SECURITY ALERT] $TARGET_DIR has permissions $DIR_PERMS (Expected: 700)"
  if [[ "$AUTO_FIX" == true ]]; then
    chmod 700 "$TARGET_DIR"
    echo "   ↳ Fixed: Applied chmod 700 to $TARGET_DIR"
  fi
else
  echo "✅ [OK] Directory permissions secure: $TARGET_DIR (700)"
fi

echo ""
echo "--- Scanning SSH Keys and Configurations ---"

# Audit Private Keys (*id_*, *.pem, *.key without .pub extension)
while IFS= read -r -d '' key_file; do
  perms=$(get_octal_perms "$key_file")
  base=$(basename "$key_file")
  
  if [[ "$key_file" == *.pub ]]; then
    # Public key should be 644
    if [[ "$perms" -ne 644 ]]; then
      echo "⚠️  [WARN] Public key $base has permissions $perms (Recommended: 644)"
      if [[ "$AUTO_FIX" == true ]]; then
        chmod 644 "$key_file"
        echo "   ↳ Fixed: Applied chmod 644 to $base"
      fi
    else
      echo "✅ [OK] Public key $base (644)"
    fi
  elif [[ "$base" == "authorized_keys" || "$base" == "config" ]]; then
    # authorized_keys & config should be 600
    if [[ "$perms" -ne 600 ]]; then
      echo "❌ [SECURITY ALERT] $base has permissions $perms (Expected: 600)"
      if [[ "$AUTO_FIX" == true ]]; then
        chmod 600 "$key_file"
        echo "   ↳ Fixed: Applied chmod 600 to $base"
      fi
    else
      echo "✅ [OK] Configuration $base (600)"
    fi
  elif [[ "$base" == "known_hosts"* ]]; then
    # known_hosts should be 644 or 600
    echo "✅ [OK] Known hosts file $base ($perms)"
  else
    # Assumed private key
    if [[ "$perms" -ne 600 ]]; then
      echo "❌ [CRITICAL] Private key $base has permissions $perms! (Must be: 600)"
      if [[ "$AUTO_FIX" == true ]]; then
        chmod 600 "$key_file"
        echo "   ↳ Fixed: Applied chmod 600 to $base"
      fi
    else
      echo "✅ [OK] Private key $base (600)"
    fi
  fi
done < <(find "$TARGET_DIR" -maxdepth 1 -type f -print0)

echo ""
echo "Audit complete."
exit 0
