#!/usr/bin/env bash

# ==============================================================================
# Script: storage_triage_analyzer.sh
# Track: Linux Fundamentals & Bash Companion - Day 21 (Disks & Filesystems)
# Objective: Comprehensive directory consumption forensics & storage triage utility:
#            1. Task b21-biggest: Print the 5 largest folders in any target directory
#            2. Task d21-du: Sort directory allocations safely without crossing filesystem boundaries
#            3. Task d21-lsblk: Correlate block devices (lsblk) with active mounts (df)
#            4. Task d21-fstab: Audit /etc/fstab for UUID and nofail best practices
#            5. Task d21-fill-disk: Controlled disk saturation simulation & cleanup
#
# Usage:
#   ./storage_triage_analyzer.sh [COMMAND] [OPTIONS] [PATH]
#
# Examples:
#   ./storage_triage_analyzer.sh                        # Top 5 folders in current directory
#   ./storage_triage_analyzer.sh /var                   # Top 5 folders in /var
#   ./storage_triage_analyzer.sh --top 10 /home         # Top 10 folders in /home
#   ./storage_triage_analyzer.sh devices                # Correlate block devices with mounts
#   ./storage_triage_analyzer.sh fstab-audit            # Audit /etc/fstab persistence & nofail flags
#   ./storage_triage_analyzer.sh simulate-fill --size 50M # Test allocation failure & cleanup
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

TOP_COUNT=5
TARGET_PATH="."
ACTION="biggest"
SIM_SIZE="50M"
CLEANUP_ONLY=false

usage() {
  cat << EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS] [DIRECTORY_PATH]

Commands:
  biggest [PATH]        Print the N largest folders in target path (default: 5)
  devices               Correlate block devices (lsblk) with mounted filesystems (df)
  fstab-audit           Audit /etc/fstab entries for UUID persistence and 'nofail' safety
  simulate-fill         Run controlled disk fill drill (Task d21-fill-disk) and clean up
  help                  Display this command manual

Options:
  -n, --top NUM         Number of largest folders to display (default: 5)
  -s, --size SIZE       File size for simulation (e.g., 50M, 100M; default: 50M)
  --cleanup             Clean up simulated dummy files immediately
  -h, --help            Show this help guide

Examples:
  $(basename "$0") /var/log                     # Find 5 biggest folders in /var/log
  $(basename "$0") --top 8 month-01-linux-and-bash
  $(basename "$0") devices
  $(basename "$0") fstab-audit
  $(basename "$0") simulate-fill --size 100M
EOF
  exit 0
}

# Subcommand and options parser
while [[ $# -gt 0 ]]; do
  case "$1" in
    biggest)
      ACTION="biggest"
      shift
      ;;
    devices|lsblk)
      ACTION="devices"
      shift
      ;;
    fstab-audit|fstab)
      ACTION="fstab-audit"
      shift
      ;;
    simulate-fill|fill-disk)
      ACTION="simulate-fill"
      shift
      ;;
    -n|--top)
      TOP_COUNT="${2:-5}"
      shift 2
      ;;
    -s|--size)
      SIM_SIZE="${2:-50M}"
      shift 2
      ;;
    --cleanup)
      CLEANUP_ONLY=true
      shift
      ;;
    -h|--help|help)
      usage
      ;;
    -*)
      echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
      exit 1
      ;;
    *)
      # Path argument
      TARGET_PATH="$1"
      shift
      ;;
  esac
done

# ------------------------------------------------------------------------------
# Task b21-biggest & Task d21-du: Find Top N Largest Folders
# ------------------------------------------------------------------------------
find_biggest_folders() {
  local target="$1"
  local count="$2"

  if [[ ! -d "$target" ]]; then
    echo -e "${RED}[ERROR]${NC} Target path '${target}' is not a valid directory." >&2
    exit 1
  fi

  # Resolve absolute path if realpath/readlink available
  local abs_path
  if command -v realpath >/dev/null 2>&1; then
    abs_path=$(realpath "$target")
  else
    abs_path="$target"
  fi

  echo -e "${BLUE}[INFO]${NC} Scanning top ${BOLD}${count}${NC} largest folders in '${BOLD}${abs_path}${NC}'..."
  echo -e "       (Using ${CYAN}-x / --one-file-system${NC} to prevent scanning across mount boundaries)"
  echo ""

  # Header
  printf "${BOLD}%-6s %-12s %-50s${NC}\n" "RANK" "SIZE" "DIRECTORY PATH"
  echo "----------------------------------------------------------------------"

  # Perform du scan defensively
  # -x: stay on one filesystem
  # --max-depth=1: immediate subdirectories only
  # 2>/dev/null: suppress permission denied warnings on restricted folders
  local rank=1
  local raw_output
  raw_output=$(du -x -k --max-depth=1 "$target" 2>/dev/null | sort -nr || true)

  if [[ -z "$raw_output" ]]; then
    echo -e "${YELLOW}[WARN]${NC} No readable subdirectories found in '${target}'."
    return 0
  fi

  # Loop over sorted lines
  while IFS=$'\t' read -r size_kb folder_path; do
    # Skip the parent folder itself if it matches target root
    if [[ "$folder_path" == "$target" ]] || [[ "$folder_path" == "." ]] || [[ "$folder_path" == "./" ]]; then
      continue
    fi

    # Convert KB to Human Readable (M, G, K)
    local human_size
    if [[ "$size_kb" -ge 1048576 ]]; then
      human_size=$(awk -v k="$size_kb" 'BEGIN {printf "%.1fG", k/1048576}')
    elif [[ "$size_kb" -ge 1024 ]]; then
      human_size=$(awk -v k="$size_kb" 'BEGIN {printf "%.1fM", k/1024}')
    else
      human_size="${size_kb}K"
    fi

    # Display rank
    printf "%-6s ${BOLD}%-12s${NC} %-50s\n" "#${rank}" "$human_size" "$folder_path"

    rank=$((rank + 1))
    if [[ "$rank" -gt "$count" ]]; then
      break
    fi
  done <<< "$raw_output"

  echo "----------------------------------------------------------------------"
  echo -e "${GREEN}[OK]${NC} Triage scan complete. Focus cleanup efforts on top-ranked paths."
}

# ------------------------------------------------------------------------------
# Task d21-lsblk & Task d21-df: Correlate Block Devices with Filesystems
# ------------------------------------------------------------------------------
audit_block_devices() {
  echo -e "${BLUE}[INFO]${NC} Correlating physical/virtual block devices with active mounts..."
  echo ""

  if command -v lsblk >/dev/null 2>&1; then
    echo -e "${BOLD}=== Block Device Topology (lsblk) ===${NC}"
    lsblk -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null || lsblk
    echo ""
  else
    echo -e "${YELLOW}[NOTICE]${NC} lsblk not available in current environment (emulated or containerized)."
  fi

  echo -e "${BOLD}=== Active Filesystem Utilization (df -h) ===${NC}"
  df -h
  echo ""

  echo -e "${CYAN}[ANALYSIS]${NC} Device Matching Guide:"
  echo "  • Physical / Virtual Disks: /dev/sd* (SCSI/SATA/EBS), /dev/nvme* (Bare-metal SSD)"
  echo "  • Look at the MOUNTPOINT column in lsblk to verify where each partition attaches."
  echo "  • Unmounted partitions (empty MOUNTPOINT) are available for format or mounting."
}

# ------------------------------------------------------------------------------
# Task d21-fstab: Audit Persistent Mount Configuration
# ------------------------------------------------------------------------------
audit_fstab() {
  local fstab_file="/etc/fstab"

  echo -e "${BLUE}[INFO]${NC} Auditing persistent mount configurations in '${fstab_file}'..."
  echo ""

  if [[ ! -f "$fstab_file" ]]; then
    echo -e "${YELLOW}[NOTICE]${NC} '${fstab_file}' not found on this system."
    echo "Displaying standard enterprise /etc/fstab template for reference:"
    cat << 'FSTAB_DEMO'
# /etc/fstab: static file system information.
# <file system>                           <mount point>  <type>  <options>                  <dump> <pass>
UUID=8f7e2d14-3c6a-49f2-8822-123456789abc /              ext4    errors=remount-ro          0      1
UUID=9a1b2c3d-4e5f-6a7b-8c9d-0123456789ef /mnt/data      ext4    defaults,nofail,noatime    0      2
/swapfile                                 none           swap    sw                         0      0
FSTAB_DEMO
    return 0
  fi

  local line_num=0
  local issues_found=0

  while read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    # Strip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue

    local dev mnt type opts dump pass
    dev=$(echo "$line" | awk '{print $1}')
    mnt=$(echo "$line" | awk '{print $2}')
    type=$(echo "$line" | awk '{print $3}')
    opts=$(echo "$line" | awk '{print $4}')
    dump=$(echo "$line" | awk '{print $5}')
    pass=$(echo "$line" | awk '{print $6}')

    echo -e "• Line ${line_num}: Device '${BOLD}${dev}${NC}' -> '${BOLD}${mnt}${NC}' (${type})"

    # Check 1: Using hardcoded device name instead of UUID
    if [[ "$dev" =~ ^/dev/sd ]] || [[ "$dev" =~ ^/dev/nvme ]] || [[ "$dev" =~ ^/dev/vd ]]; then
      echo -e "    ${YELLOW}⚠️ WARNING: Fragile device name '${dev}' detected.${NC}"
      echo -e "       Best practice: Use 'UUID=...' via blkid to prevent mount failure if device letter shifts."
      issues_found=$((issues_found + 1))
    fi

    # Check 2: Missing nofail on secondary data mounts
    if [[ "$mnt" != "/" ]] && [[ "$type" != "swap" ]] && ! [[ "$opts" =~ nofail ]]; then
      echo -e "    ${YELLOW}⚠️ NOTICE: Non-root mount point '${mnt}' lacks 'nofail' flag.${NC}"
      echo -e "       Risk: If this disk fails to attach at boot, systemd halts into emergency.target."
      issues_found=$((issues_found + 1))
    fi

  done < "$fstab_file"

  echo ""
  if [[ "$issues_found" -eq 0 ]]; then
    echo -e "${GREEN}[OK]${NC} All /etc/fstab entries conform to enterprise resilience standards."
  else
    echo -e "${YELLOW}[AUDIT COMPLETE]${NC} Found ${issues_found} potential configuration optimizations."
  fi
}

# ------------------------------------------------------------------------------
# Task d21-fill-disk: Controlled Saturation Simulation & Recovery
# ------------------------------------------------------------------------------
simulate_disk_fill() {
  local test_dir="/tmp/devops_storage_drill"
  local test_file="${test_dir}/synthetic_saturation.bin"

  if [[ "$CLEANUP_ONLY" == true ]]; then
    echo -e "${BLUE}[CLEANUP]${NC} Removing simulated test artifacts..."
    rm -rf "$test_dir"
    echo -e "${GREEN}[OK]${NC} Sandbox '${test_dir}' purged successfully."
    return 0
  fi

  echo -e "${BLUE}[SIMULATION]${NC} Running Task d21-fill-disk: Controlled Disk Saturation Drill"
  mkdir -p "$test_dir"

  echo -e "1. Allocating dummy test file of size ${BOLD}${SIM_SIZE}${NC} in '${test_file}'..."
  
  if command -v fallocate >/dev/null 2>&1; then
    fallocate -l "$SIM_SIZE" "$test_file" 2>/dev/null || dd if=/dev/zero of="$test_file" bs=1M count=50 status=none
  else
    dd if=/dev/zero of="$test_file" bs=1M count=50 status=none
  fi

  echo -e "2. Inspecting simulated space consumer:"
  ls -lh "$test_file"
  echo ""

  echo -e "3. Simulating disk pressure notification:"
  echo -e "   ${YELLOW}[WARN] Storage threshold exceeded by test artifact.${NC}"
  echo ""

  echo -e "4. Immediate remediation & cleanup:"
  rm -f "$test_file"
  rmdir "$test_dir" 2>/dev/null || true
  echo -e "   ${GREEN}[OK] Synthetic file removed. Space restored.${NC}"
}

# ------------------------------------------------------------------------------
# Main Execution Dispatcher
# ------------------------------------------------------------------------------
case "$ACTION" in
  biggest)
    find_biggest_folders "$TARGET_PATH" "$TOP_COUNT"
    ;;
  devices)
    audit_block_devices
    ;;
  fstab-audit)
    audit_fstab
    ;;
  simulate-fill)
    simulate_disk_fill
    ;;
  *)
    usage
    ;;
esac
