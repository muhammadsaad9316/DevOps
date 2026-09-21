# Day 17: Job Control, Detached Sessions & Parallel Script Execution

## 🧠 Linux Job Control Architecture & Process Groups

When running commands in an interactive Linux shell, every command runs inside a **session** associated with a **controlling terminal (TTY/PTY)**. To orchestrate multiple concurrent tasks within a single terminal, the Linux kernel and the POSIX shell provide **Job Control**.

```text
                     ┌────────────────────────────────────────┐
                     │          Controlling TTY / PTY         │
                     └───────────────────┬────────────────────┘
                                         │
                        ┌────────────────┴────────────────┐
                        ▼                                 ▼
             [Foreground Process Group]       [Background Process Groups]
             • Has terminal read/write        • Detached from stdin
             • Receives Ctrl+C (SIGINT)       • Output goes to tty (or redirected)
             • Receives Ctrl+Z (SIGTSTP)      • Suspended if reading stdin (SIGTTIN)
```

### 1. Foreground vs. Background Process Groups
- **Foreground Process**: A process group that currently owns the terminal's input stream (`stdin`). The shell waits for it to complete before displaying the next prompt. Only **one** process group can be in the foreground at any given time.
- **Background Process**: A process group running asynchronously in the background. It does not block the shell prompt. If a background process attempts to read from standard input (`stdin`), the kernel sends it a `SIGTTIN` signal, suspending it until brought to the foreground.

---

## ⚡ Terminal Signals & Job Control Commands

### Key Terminal Control Signals

| Key Combination | Signal | Signal Number | Meaning & Kernel Action |
|:---:|:---:|:---:|---|
| `Ctrl + C` | **`SIGINT`** | `2` | Interrupt signal. Requests graceful termination of foreground process. |
| `Ctrl + Z` | **`SIGTSTP`** | `20` | Terminal stop signal. Suspends (freezes) foreground process into memory. |
| `Ctrl + \` | **`SIGQUIT`** | `3` | Quit signal. Terminates process and triggers a core dump. |

### Shell Built-in Job Management Commands

```bash
# 1. Run a command in the background immediately
sleep 300 &
# Output: [1] 48291  ([JobID] PID)

# 2. Inspect active jobs tracked by the current shell
jobs -l

# 3. Resume a stopped job in the background (sends SIGCONT)
bg %1

# 4. Bring a background or stopped job to the foreground
fg %1

# 5. Terminate a specific job via its Job ID
kill %1
```

### Understanding `jobs -l` Output

```text
[1]+ 48291 Running                 sleep 300 &
[2]- 48305 Stopped                 nano config.yaml
```
- `[1]`, `[2]`: **Job ID** (distinct from OS PID).
- `+`: The **current default job** (target of bare `fg` or `bg`).
- `-`: The **previous job** (will become default if current job finishes).
- `48291`: The Linux operating system **PID**.
- `Running` / `Stopped`: The current kernel execution state.

---

## 🛡️ Surviving Terminal Disconnects: `nohup`, `disown`, and `tmux`

When an SSH session terminates or an engineer closes their terminal window, the kernel closes the controlling PTY and automatically transmits a **`SIGHUP` (Signal 1 - Hangup)** to all foreground and background child processes attached to that terminal session. By default, processes terminate upon receiving `SIGHUP`.

```text
[ SSH Connection Drops ]
           │
           ▼
[ Kernel Closes PTY ] ─── sends SIGHUP (1) ───► [ Child Processes Die ]
```

### 1. The `nohup` Utility (No Hang Up)
`nohup` wraps an executable, making it completely immune to `SIGHUP`. Additionally, if standard output or error are not redirected, `nohup` automatically redirects them to a persistent file (`nohup.out`).

```bash
# Execute long task immune to SIGHUP, discarding stdin, logging output
nohup python3 -u data_migration.py > migration.log 2>&1 &
```

### 2. The Shell `disown` Built-in
If a long process was already started in the background without `nohup`, use `disown` to detach it from the shell's active job table:

```bash
# Start background job
tar -czf backup_large.tar.gz /var/data &

# Prevent shell from sending SIGHUP upon session exit
disown -h %1

# Or completely remove job from shell table
disown %1
```

### 3. Modern Production Standard: `tmux` (Terminal Multiplexer)
In modern cloud infrastructure, running long-running operations via bare `nohup` is error-prone. **`tmux`** creates an isolated, persistent client-server session managed by a background server daemon. Even if the local laptop reboots, Wi-Fi drops, or SSH crashes, the processes running inside `tmux` continue unabated.

```text
 ┌──────────────────────────────────────────────────────────┐
 │                      tmux Server                         │
 │  (Independent UNIX socket daemon: survives SSH disconnect) │
 │                                                          │
 │   ┌────────────────────────┐    ┌────────────────────┐   │
 │   │ Session: "production"  │    │  Session: "backup" │   │
 │   │ Window 0: htop         │    │  Window 0: rsync   │   │
 │   │ Window 1: logs (tail)  │    │                    │   │
 │   └────────────────────────┘    └────────────────────┘   │
 └────────────────────────────┬─────────────────────────────┘
                              ▲
                       tmux attach / detach
                              ▼
                [ Engineer's Terminal / SSH ]
```

#### Essential `tmux` Lifecycle Commands

| Action | Command | SRE Note |
|---|---|---|
| **Create Named Session** | `tmux new -s deploy-session` | Always use descriptive session names. |
| **Detach from Session** | Press `Ctrl+b`, then press `d` | Leaves all session processes running in background. |
| **List Active Sessions** | `tmux ls` | Lists sessions, window counts, and creation timestamps. |
| **Reattach to Session** | `tmux attach -t deploy-session` | Resumes terminal exactly where you left off. |
| **Kill / Terminate Session** | `tmux kill-session -t deploy-session` | Closes session and terminates all contained child processes. |

---

## 🤖 Automation Companion: Background Tasks & Parallelism in Bash

### 1. Spawning Asynchronous Background Jobs: `&` and `$!`
In Bash scripts, appending `&` to any command, subshell, or function executes it asynchronously in a background subshell. Bash immediately sets the special parameter **`$!`** to the PID of that newly spawned background process.

```bash
# Spawn asynchronous backup
./run_backup.sh &
BACKUP_PID=$!
echo "Backup launched with PID: $BACKUP_PID"
```

### 2. Process Synchronization: The `wait` Command
A script often needs to spawn multiple background tasks and pause until one or all tasks complete.

- **`wait` (bare)**: Pauses execution until **all** background child processes spawned by the current shell terminate.
- **`wait "$PID"`**: Blocks until the specific PID terminates and **returns that process's exit code**.

```bash
# Wait for specific process and capture its exit code
wait "$BACKUP_PID"
EXIT_CODE=$?

if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "Backup completed successfully."
else
  echo "ERROR: Backup failed with exit status $EXIT_CODE" >&2
fi
```

### 3. Production Fan-Out / Fan-In Parallelism Pattern
Executing independent tasks sequentially wastes compute capacity. The **Fan-Out / Fan-In** pattern executes $N$ jobs concurrently (Fan-Out), captures all PIDs, and then waits for all jobs to finish while collecting individual exit codes (Fan-In):

```bash
#!/usr/bin/env bash
set -euo pipefail

declare -A JOB_PIDS
TARGETS=("db_replica" "app_cache" "search_indexer")

# --- FAN-OUT: Dispatch parallel tasks ---
for target in "${TARGETS[@]}"; do
  (
    echo "[$(date +%T)] Starting refresh for $target..."
    sleep 3
    echo "[$(date +%T)] Finished refresh for $target."
  ) &
  JOB_PIDS["$target"]=$!
done

# --- FAN-IN: Synchronize & collect exit codes ---
FAILED=0
for target in "${!JOB_PIDS[@]}"; do
  pid="${JOB_PIDS[$target]}"
  if wait "$pid"; then
    echo "✅ Target '$target' (PID $pid) succeeded."
  else
    echo "❌ Target '$target' (PID $pid) FAILED." >&2
    FAILED=1
  fi
done

exit "$FAILED"
```

### 4. Defensive Signal Trapping in Parallel Scripts
A critical flaw in naive parallel scripts is that if a user terminates the parent script (`Ctrl+C`), the background child jobs continue running as detached orphans. A defensive script registers a trap to kill all tracked child PIDs upon receiving `SIGINT` or `SIGTERM`:

```bash
CHILD_PIDS=()

cleanup() {
  echo -e "\n🛑 Interrupted! Terminating all running child processes..."
  for pid in "${CHILD_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
    fi
  done
  exit 130
}

trap cleanup SIGINT SIGTERM
```

---

## 🛠️ Hands-On Drills: Job Control & Parallel Workflows

### Drill 1: Interactive Job Control (`Ctrl+Z`, `jobs`, `bg`, `fg`)
```bash
# 1. Start a foreground sleep command
sleep 120

# 2. Press Ctrl+Z in your terminal
# Terminal displays: [1]+  Stopped    sleep 120

# 3. Check status in job table
jobs -l

# 4. Resume execution in background
bg %1
# Terminal displays: [1]+ sleep 120 &

# 5. Bring back to foreground and interrupt
fg %1
# Press Ctrl+C to terminate
```

### Drill 2: Managing Three Concurrent Background Jobs
```bash
# Spawn 3 sleep jobs with different durations
sleep 100 &
sleep 200 &
sleep 300 &

# Inspect all jobs
jobs -l

# Kill the second job directly via Job ID
kill %2

# Verify updated job table
jobs -l
# Clean up remaining jobs
kill %1 %3
```

### Drill 3: Surviving Terminal Death with `nohup`
```bash
# Run a loop writing to disk via nohup
nohup bash -c 'for i in $(seq 1 100); do echo "Heartbeat $i at $(date)" >> /tmp/nohup_test.log; sleep 2; done' > /dev/null 2>&1 &
NOHUP_PID=$!
echo "Process running under PID: $NOHUP_PID"

# Close the terminal or exit the SSH session completely.
# Open a new terminal and verify the process is still running:
ps -p "$NOHUP_PID" -o pid,ppid,stat,cmd

# Clean up
kill -15 "$NOHUP_PID"
```

### Drill 4: Persistent Session Management with `tmux`
```bash
# 1. Create a persistent named session
tmux new -s sre-session

# 2. Inside tmux, run a live monitor
top

# 3. Detach from tmux by pressing: Ctrl+b, then d
# You are back in your base shell. top is still executing.

# 4. Confirm session exists
tmux ls

# 5. Reattach to session
tmux attach -t sre-session

# 6. Exit the session cleanly
exit
```

---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: SSH Network Severance Halts Unattended Multi-Gigabyte Database Migration
- **Symptom / Alert**: P1 Production Incident. During off-peak maintenance, a multi-terabyte schema migration and index rebuild halted at 38%. Database connection pool spiked to 100% saturation, locking critical production tables (`Waiting for table metadata lock`). Application requests failed with HTTP 504 Gateway Timeout.
- **Investigation & Triage**:
  - The on-call DBA ran a custom migration script directly from their local laptop over an interactive SSH session without `tmux` or `nohup`.
  - At 02:14 UTC, the engineer's residential ISP experienced a brief transient dropout (30-second loss of connectivity).
  - The server's OpenSSH daemon (`sshd`) detected client TCP timeout after `ClientAliveInterval` elapsed and closed the controlling pseudo-terminal (`/dev/pts/3`).
  - The Linux kernel immediately broadcasted `SIGHUP` (Signal 1) to all process groups bound to `/dev/pts/3`.
  - The migration script, having no handler for `SIGHUP`, crashed immediately mid-execution while holding exclusive DDL table locks on core billing tables.
- **Root Cause Analysis (RCA)**:
  - Critical infrastructure tasks were executed in an ephemeral, interactive shell bound to client network reliability.
  - Absence of a signal trap or transaction rollback mechanism left the database engine waiting for abandoned lock release.
- **Remediation & Prevention Policy**:
  1. **Immediate Fix**: Identified blocked Postgres/MySQL backend sessions using `pg_stat_activity` / `SHOW FULL PROCESSLIST`, terminated stalled migration backends via `pg_terminate_backend()`, and rolled back incomplete DDL.
  2. **Architectural Guardrail**: Instituted a mandatory infrastructure policy: **All remote maintenance, deployments, and long-running batch jobs must execute inside detached `tmux` sessions or Systemd transient service units (`systemd-run`)**.
  3. **Script Hardening**: Updated migration wrappers to use defensive `trap` routines that catch `SIGHUP` / `SIGTERM` and issue an orderly transactional rollback.
