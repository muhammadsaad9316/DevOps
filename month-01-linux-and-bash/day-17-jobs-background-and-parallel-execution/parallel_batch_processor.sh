#!/usr/bin/env bash

# ==============================================================================
# Script: parallel_batch_processor.sh
# Track: Bash Companion - Day 17 (Background Jobs & Parallelism)
# Objective: Production-grade Fan-Out / Fan-In parallel task runner demonstrating:
#            1. Asynchronous execution of multiple concurrent background jobs (&)
#            2. Process ID capture via $! and child process tracking
#            3. Defensive signal propagation (SIGINT/SIGTERM) to prevent orphans
#            4. Targeted process synchronization and exit code collection via wait
#            5. Structured execution audit summary
#
# Usage: ./parallel_batch_processor.sh [--simulate-failure]
# ==============================================================================

set -euo pipefail

# Color tokens for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SIMULATE_FAILURE="${1:-}"

# Global tracking structures
declare -a TASK_NAMES=("db_snapshot" "asset_compression" "log_aggregation" "cache_prewarm")
declare -a TASK_DURATIONS=(3 4 2 3)
declare -A TASK_PIDS
declare -A TASK_STATUS
declare -a RUNNING_PIDS=()

log_info() {
  echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $*" >&2
}

# Cleanup trap: Ensures all spawned child processes are killed if parent is interrupted
cleanup_children() {
  echo ""
  log_warn "Signal intercepted! Aborting parallel execution..."
  for pid in "${RUNNING_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      log_warn "Sending SIGTERM to child worker PID $pid..."
      kill -TERM "$pid" 2>/dev/null || true
    fi
  done
  log_error "Execution aborted by operator. All child processes reaped."
  exit 130
}

trap cleanup_children SIGINT SIGTERM

# Worker function executed in a background subshell
worker_task() {
  local name="$1"
  local duration="$2"
  local should_fail="$3"
  local worker_pid=$$

  echo "  --> [PID $worker_pid] Starting worker task: $name (Estimated: ${duration}s)"
  sleep "$duration"

  if [[ "$should_fail" == "true" && "$name" == "log_aggregation" ]]; then
    echo "  <-- [PID $worker_pid] Worker task $name encountered critical error!" >&2
    return 1
  fi

  echo "  <-- [PID $worker_pid] Worker task $name completed successfully."
  return 0
}

# Banner
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}        PARALLEL BATCH PROCESSOR & JOB CONTROLLER           ${NC}"
echo -e "${CYAN}============================================================${NC}"
log_info "Master Coordinator PID : $$"
log_info "Total Parallel Tasks   : ${#TASK_NAMES[@]}"
if [[ "$SIMULATE_FAILURE" == "--simulate-failure" ]]; then
  log_warn "Failure simulation flag enabled: 'log_aggregation' will exit with code 1"
fi
echo ""

START_TIME=$(date +%s)

# ==============================================================================
# PHASE 1: FAN-OUT (Dispatch all tasks asynchronously in parallel)
# ==============================================================================
log_info "Phase 1: Fan-Out - Dispatching background tasks concurrently..."

for i in "${!TASK_NAMES[@]}"; do
  task="${TASK_NAMES[$i]}"
  duration="${TASK_DURATIONS[$i]}"
  should_fail="false"
  if [[ "$SIMULATE_FAILURE" == "--simulate-failure" ]]; then
    should_fail="true"
  fi

  # Execute in background via &
  worker_task "$task" "$duration" "$should_fail" &
  child_pid=$!

  TASK_PIDS["$task"]=$child_pid
  RUNNING_PIDS+=("$child_pid")
  log_info "Dispatched '$task' -> Background Job PID: $child_pid"
done

echo ""
log_info "All tasks dispatched in parallel. Shell is free to perform other work."
log_info "Active background child PIDs: ${RUNNING_PIDS[*]}"
echo ""

# ==============================================================================
# PHASE 2: FAN-IN (Synchronize and collect individual exit codes)
# ==============================================================================
log_info "Phase 2: Fan-In - Awaiting completion and collecting exit codes via 'wait'..."

FAILED_COUNT=0
SUCCESS_COUNT=0

for task in "${TASK_NAMES[@]}"; do
  pid="${TASK_PIDS[$task]}"
  log_info "Waiting on task '$task' (PID: $pid)..."

  # wait $pid blocks until that specific child terminates and returns its exit code
  if wait "$pid"; then
    TASK_STATUS["$task"]="SUCCESS (0)"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    log_success "Task '$task' (PID: $pid) finished with exit code 0."
  else
    exit_code=$?
    TASK_STATUS["$task"]="FAILED ($exit_code)"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    log_error "Task '$task' (PID: $pid) FAILED with exit code $exit_code."
  fi
done

TOTAL_TIME=$(( $(date +%s) - START_TIME ))

# ==============================================================================
# PHASE 3: EXECUTION SUMMARY & AUDIT TABLE
# ==============================================================================
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}                PARALLEL EXECUTION AUDIT                    ${NC}"
echo -e "${CYAN}============================================================${NC}"
printf "%-22s %-10s %-15s\n" "Task Name" "PID" "Exit Status"
echo "------------------------------------------------------------"
for task in "${TASK_NAMES[@]}"; do
  printf "%-22s %-10s %-15s\n" "$task" "${TASK_PIDS[$task]}" "${TASK_STATUS[$task]}"
done
echo "------------------------------------------------------------"
echo -e "Total Tasks Executed : ${#TASK_NAMES[@]}"
echo -e "Successful Tasks     : ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "Failed Tasks         : $( [[ $FAILED_COUNT -gt 0 ]] && echo -e "${RED}${FAILED_COUNT}${NC}" || echo "0" )"
echo -e "Total Elapsed Time   : ${TOTAL_TIME}s (vs. ~12s sequential runtime)"
echo -e "${CYAN}============================================================${NC}"

if [[ "$FAILED_COUNT" -gt 0 ]]; then
  log_error "Batch execution completed with failures. Exiting with status 1."
  exit 1
fi

log_success "All parallel background tasks completed cleanly. Exiting 0."
exit 0
