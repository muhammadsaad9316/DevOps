#!/usr/bin/env bash

# ==============================================================================
# Script: disk_space_sentinel.sh
# Track: Bash Companion - Day 21 (Disk And Space Scripts)
# Objective: Production-grade storage sentinel and health monitor:
#            1. Task b21-disk-check: Print disk usage as a raw percentage number only
#            2. Task b21-warn-full: Alert when usage exceeds configurable warning/critical thresholds
#            3. Support path targets, inode checking, multi-mount scanning, and JSON telemetry
#            4. Standard exit code contract: 0 = OK, 1 = WARN, 2 = CRITICAL
#
# Usage:
#   ./disk_space_sentinel.sh [OPTIONS]
#
# Examples:
#   ./disk_space_sentinel.sh --raw                      # Outputs pure integer e.g. 74
#   ./disk_space_sentinel.sh                            # Checks / with defaults (warn 80%, crit 90%)
#   ./disk_space_sentinel.sh --path /var --warn 70      # Audit specific mount with 70% warn threshold
#   ./disk_space_sentinel.sh --inodes                   # Audit inode usage instead of block usage
#   ./disk_space_sentinel.sh --all                      # Audit all active mounted filesystems
#   ./disk_space_sentinel.sh --mock-usage 85 --warn 80  # Test threshold alert simulation
# ==============================================================================

set -euo pipefail

# Visual color indicators
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default configuration
TARGET_PATH="/"
WARN_THRESHOLD=80
CRIT_THRESHOLD=90
CHECK_INODES=false
RAW_PERCENT_ONLY=false
SCAN_ALL=false
JSON_OUTPUT=false
MOCK_USAGE=""

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Task b21 Requirements:
  - Prints disk usage as a percentage number only (--raw)
  - Emits colorized warnings when usage exceeds configurable thresholds

Options:
  -r, --raw             Print usage percentage as integer only (Task b21-disk-check)
  -p, --path PATH       Target directory path or mount point to inspect (default: /)
  -w, --warn PERCENT    Warning threshold percentage (default: 80)
  -c, --crit PERCENT    Critical threshold percentage (default: 90)
  -t, --threshold NUM   Alias for --warn threshold
  -i, --inodes          Audit inode saturation instead of block storage space
  -a, --all             Scan and report all active physical mounted filesystems
  -j, --json            Format output as JSON document for observability collectors
  --mock-usage NUM      Simulate usage percentage for testing without altering disk
  -h, --help            Show this help guide

Exit Status Contract:
  0 = OK (Usage below warning threshold)
  1 = WARNING (Usage exceeds warning threshold)
  2 = CRITICAL (Usage exceeds critical threshold)
  3 = CONFIGURATION / EXECUTION ERROR
EOF
  exit 0
}

# Parse CLI options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--raw)
      RAW_PERCENT_ONLY=true
      shift
      ;;
    -p|--path)
      TARGET_PATH="${2:-}"
      if [[ -z "$TARGET_PATH" ]]; then
        echo -e "${RED}[ERROR]${NC} Missing path argument." >&2
        exit 3
      fi
      shift 2
      ;;
    -w|--warn)
      WARN_THRESHOLD="${2:-}"
      shift 2
      ;;
    -c|--crit)
      CRIT_THRESHOLD="${2:-}"
      shift 2
      ;;
    -t|--threshold)
      WARN_THRESHOLD="${2:-}"
      shift 2
      ;;
    -i|--inodes)
      CHECK_INODES=true
      shift
      ;;
    -a|--all)
      SCAN_ALL=true
      shift
      ;;
    -j|--json)
      JSON_OUTPUT=true
      shift
      ;;
    --mock-usage)
      MOCK_USAGE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
      echo "Use $(basename "$0") --help for valid arguments." >&2
      exit 3
      ;;
  esac
done

# Validate threshold integers
validate_integer() {
  local val="$1"
  local name="$2"
  if ! [[ "$val" =~ ^[0-9]+$ ]] || [[ "$val" -lt 0 ]] || [[ "$val" -gt 100 ]]; then
    echo -e "${RED}[ERROR]${NC} ${name} must be an integer between 0 and 100 (got: '${val}')." >&2
    exit 3
  fi
}

validate_integer "$WARN_THRESHOLD" "Warning threshold"
validate_integer "$CRIT_THRESHOLD" "Critical threshold"

if [[ "$WARN_THRESHOLD" -gt "$CRIT_THRESHOLD" ]]; then
  echo -e "${RED}[ERROR]${NC} Warning threshold (${WARN_THRESHOLD}%) cannot be higher than Critical threshold (${CRIT_THRESHOLD}%)." >&2
  exit 3
fi

# Fallback path if target doesn't exist
if [[ ! -e "$TARGET_PATH" ]]; then
  if [[ -d "." ]]; then
    TARGET_PATH="."
  else
    TARGET_PATH="/"
  fi
fi

# ------------------------------------------------------------------------------
# Task b21-disk-check: Extract pure integer usage percentage
# ------------------------------------------------------------------------------
get_disk_usage_percent() {
  local path="$1"
  local check_ino="$2"

  if [[ -n "$MOCK_USAGE" ]]; then
    echo "$MOCK_USAGE"
    return 0
  fi

  local flag="-P"
  if [[ "$check_ino" == true ]]; then
    flag="-Pi"
  fi

  # POSIX portable df output parsing (-P prevents line wrapping)
  local percent
  percent=$(df "$flag" "$path" 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $(NF-1)); print $(NF-1)}')

  if [[ -z "$percent" ]] || ! [[ "$percent" =~ ^[0-9]+$ ]]; then
    # Fallback attempt parsing standard columns
    percent=$(df "$path" 2>/dev/null | awk 'NR==2 {for(i=1;i<=NF;i++) if($i ~ /%/) {gsub(/%/, "", $i); print $i; exit}}')
  fi

  echo "${percent:-0}"
}

# ------------------------------------------------------------------------------
# Query filesystem metadata line (right-anchored to support spaces in device names)
# ------------------------------------------------------------------------------
get_fs_metrics() {
  local path="$1"
  local check_ino="$2"
  local flag="-Ph"
  if [[ "$check_ino" == true ]]; then
    flag="-Pih"
  fi

  df "$flag" "$path" 2>/dev/null | awk 'NR==2 {
    mount = $NF;
    pct = $(NF-1);
    avail = $(NF-2);
    used = $(NF-3);
    total = $(NF-4);
    dev = "";
    for(i = 1; i <= NF-5; i++) {
      dev = (dev ? dev " " : "") $i;
    }
    if (dev == "") dev = $1;
    print dev "|" total "|" used "|" avail "|" pct "|" mount;
  }' || true
}

# Fast path: Task b21-disk-check raw output
if [[ "$RAW_PERCENT_ONLY" == true ]]; then
  get_disk_usage_percent "$TARGET_PATH" "$CHECK_INODES"
  exit 0
fi

# ------------------------------------------------------------------------------
# Audit and Alert Single Path
# ------------------------------------------------------------------------------
audit_path() {
  local path="$1"
  local usage_pct
  usage_pct=$(get_disk_usage_percent "$path" "$CHECK_INODES")

  local fs_info
  fs_info=$(get_fs_metrics "$path" "$CHECK_INODES")
  
  local fs_dev total_sz used_sz avail_sz pct_col mount_pt
  fs_dev=$(echo "$fs_info" | cut -d'|' -f1)
  total_sz=$(echo "$fs_info" | cut -d'|' -f2)
  used_sz=$(echo "$fs_info" | cut -d'|' -f3)
  avail_sz=$(echo "$fs_info" | cut -d'|' -f4)
  mount_pt=$(echo "$fs_info" | cut -d'|' -f6)
  
  [[ -z "$fs_dev" ]] && fs_dev="virtual-fs"
  [[ -z "$total_sz" ]] && total_sz="N/A"
  [[ -z "$used_sz" ]] && used_sz="N/A"
  [[ -z "$avail_sz" ]] && avail_sz="N/A"
  [[ -z "$mount_pt" ]] && mount_pt="$path"

  local status_code=0
  local status_label="OK"
  local color="$GREEN"

  if [[ "$usage_pct" -ge "$CRIT_THRESHOLD" ]]; then
    status_code=2
    status_label="CRITICAL"
    color="$RED"
  elif [[ "$usage_pct" -ge "$WARN_THRESHOLD" ]]; then
    status_code=1
    status_label="WARNING"
    color="$YELLOW"
  fi

  if [[ "$JSON_OUTPUT" == true ]]; then
    cat << JSON
{
  "target_path": "$path",
  "mount_point": "$mount_pt",
  "device": "$fs_dev",
  "metric_type": "$([ "$CHECK_INODES" == true ] && echo "inodes" || echo "blocks")",
  "usage_percent": $usage_pct,
  "warn_threshold": $WARN_THRESHOLD,
  "crit_threshold": $CRIT_THRESHOLD,
  "total_capacity": "$total_sz",
  "used": "$used_sz",
  "available": "$avail_sz",
  "status": "$status_label"
}
JSON
    return "$status_code"
  fi

  # Visual terminal summary
  local metric_name="Storage Space"
  if [[ "$CHECK_INODES" == true ]]; then
    metric_name="Inode Capacity"
  fi

  echo -e "${color}[${status_label}]${NC} ${BOLD}${metric_name}${NC} on '${BOLD}${mount_pt}${NC}' (${fs_dev}):"
  echo -e "         Usage:     ${color}${usage_pct}%${NC} (Warn: ${WARN_THRESHOLD}%, Crit: ${CRIT_THRESHOLD}%)"
  echo -e "         Breakdown: Used: ${used_sz} | Avail: ${avail_sz} | Total: ${total_sz}"

  # Task b21-warn-full threshold warning messaging
  if [[ "$status_code" -eq 2 ]]; then
    echo -e "         ${RED}🚨 ALERT: Disk consumption has breached CRITICAL threshold (${usage_pct}% >= ${CRIT_THRESHOLD}%)${NC}" >&2
    echo -e "         ${RED}Action required: Clean cache, unlinked files, or expand volume immediately.${NC}" >&2
  elif [[ "$status_code" -eq 1 ]]; then
    echo -e "         ${YELLOW}⚠️ WARNING: Disk consumption has exceeded WARNING threshold (${usage_pct}% >= ${WARN_THRESHOLD}%)${NC}" >&2
    echo -e "         ${YELLOW}Action: Identify space hogs using storage_triage_analyzer.sh.${NC}" >&2
  fi

  return "$status_code"
}

# ------------------------------------------------------------------------------
# Audit All Physical Filesystems
# ------------------------------------------------------------------------------
audit_all() {
  echo -e "${BLUE}[INFO]${NC} Auditing all active mounted filesystems..."
  printf "${BOLD}%-22s %-12s %-8s %-8s %-8s %-8s %-10s${NC}\n" "FILESYSTEM" "MOUNT" "TOTAL" "USED" "AVAIL" "USE%" "STATUS"
  echo "----------------------------------------------------------------------------------"

  local worst_status=0

  # Gather mounted physical filesystems (right-anchored pipe parsing)
  while IFS='|' read -r fs total used avail pcent mount; do
    [[ -z "$fs" ]] && continue
    
    local clean_pct="${pcent//%/}"
    clean_pct="${clean_pct// /}"
    if ! [[ "$clean_pct" =~ ^[0-9]+$ ]]; then
      continue
    fi

    local st_label="OK"
    local col="$GREEN"
    if [[ "$clean_pct" -ge "$CRIT_THRESHOLD" ]]; then
      st_label="CRITICAL"
      col="$RED"
      [[ "$worst_status" -lt 2 ]] && worst_status=2
    elif [[ "$clean_pct" -ge "$WARN_THRESHOLD" ]]; then
      st_label="WARNING"
      col="$YELLOW"
      [[ "$worst_status" -lt 1 ]] && worst_status=1
    fi

    printf "%-22s %-12s %-8s %-8s %-8s ${col}%-8s %-10s${NC}\n" \
      "${fs:0:21}" "${mount:0:11}" "$total" "$used" "$avail" "${clean_pct}%" "[$st_label]"

  done < <(df -Ph 2>/dev/null | awk 'NR>1 {
    mount = $NF;
    pct = $(NF-1);
    avail = $(NF-2);
    used = $(NF-3);
    total = $(NF-4);
    dev = "";
    for(i = 1; i <= NF-5; i++) {
      dev = (dev ? dev " " : "") $i;
    }
    if (dev == "") dev = $1;
    print dev "|" total "|" used "|" avail "|" pct "|" mount;
  }')

  echo "----------------------------------------------------------------------------------"
  return "$worst_status"
}

# Execution Dispatcher
if [[ "$SCAN_ALL" == true ]]; then
  audit_all
  exit $?
else
  set +e
  audit_path "$TARGET_PATH"
  exit_code=$?
  set -e
  exit "$exit_code"
fi
