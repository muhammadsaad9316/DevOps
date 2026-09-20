# Day 16: Linux Process Lifecycle, Signals & Process Supervision

## 🧠 Linux Process Architecture & Kernel Lifecycle

A **process** is an active, executing instance of a computer program loaded into memory. In Linux, every process is assigned a unique **Process Identifier (PID)** and is created via the `fork()` and `execve()` system call pair.

### The Process Tree & PID 1
- **PID 1 (`systemd`)**: The root of the user-space process tree. Initialized directly by the Linux kernel at boot time. All other services, daemons, and user shells are descendants of PID 1.
- **PPID (Parent Process ID)**: The PID of the process that spawned the child. When a process finishes execution, its parent reads its termination status via `wait()` or `waitpid()`.

```text
               [ Linux Kernel ]
                      │
                 (PID 1: systemd)
             ┌────────┼────────┐
             │                 │
    (sshd: PID 812)     (cron: PID 904)
           │
     (bash: PID 1420)
           │
    (python: PID 2819)
```

---

## 📊 Process States & Inspection

Linux processes transition through several distinct states managed by the kernel scheduler:

| State Code | Name | Description | SRE Consideration |
|:---:|---|---|---|
| **`R`** | Running / Runnable | Actively executing on CPU or waiting in CPU run-queue. | High count of `R` processes drives high load average. |
| **`S`** | Interruptible Sleep | Waiting for an event or resource (network packet, timer, I/O). | Normal state for idle daemons. Wakes on signals. |
| **`D`** | Uninterruptible Sleep | Deep sleep waiting on hardware/disk I/O. Cannot be killed by any signal (even `SIGKILL`). | High `D` count indicates failing storage or dead NFS mounts. |
| **`Z`** | Zombie / Defunct | Terminated process whose parent has not yet read exit code via `wait()`. | Consumes zero CPU/RAM, but hogs a slot in the kernel PID table. |
| **`T`** | Stopped | Suspended by job control signal (`Ctrl+Z`, `SIGSTOP`). | Can be resumed with `SIGCONT` or `fg`/`bg`. |

### Key Inspection Tools

#### 1. `ps aux` Output Columns
```bash
ps aux | head -n 5
```
- **`USER`**: Owner account running the process.
- **`PID`**: Process identifier.
- **`%CPU` / `%MEM`**: Percentage of CPU and physical RAM utilized.
- **`VSZ`**: Virtual Memory Size (total memory allocated including shared libraries).
- **`RSS`**: Resident Set Size (actual physical RAM currently occupied in KiB).
- **`TTY`**: Controlling terminal (`?` indicates background daemon).
- **`STAT`**: Current process state (`R`, `S`, `Ss`, `Z`, `D`).
- **`START` / `TIME`**: Launch time and cumulative CPU execution time.
- **`COMMAND`**: Binary name and CLI arguments.

#### 2. Process Tree & Filtering
```bash
# View process hierarchy with PIDs
pstree -p -s $$

# Find PID by process name
pgrep -l nginx

# Detailed custom output
ps -eo pid,ppid,user,%cpu,%mem,stat,comm --sort=-%cpu | head -n 10
```

---

## 🛑 POSIX Signals: Why `kill -9` is a Last Resort

Processes communicate and handle lifecycle events via **signals**.

| Signal Name | Number | Default Action | Catchable? | Production Use Case |
|---|:---:|---|:---:|---|
| **`SIGTERM`** | `15` | Polite termination | **Yes** | **Default and standard shutdown**. Allows process to flush buffers, finish transactions, and release locks. |
| **`SIGKILL`** | `9` | Forceful kill | **No** | **Extreme emergency only**. Kernel terminates process memory instantly. |
| **`SIGHUP`** | `1` | Hangup / Reload | **Yes** | Instructs daemons (Nginx, Prometheus) to reload configuration without downtime. |
| **`SIGINT`** | `2` | Terminal interrupt | **Yes** | Sent by `Ctrl+C` from the active terminal. |
| **`SIGSTOP`** | `19` | Pause execution | **No** | Freezes process execution immediately. |
| **`SIGCONT`** | `18` | Resume execution | **Yes** | Unfreezes a paused process. |

### ⚠️ The Architectural Danger of `kill -9` (`SIGKILL`)
When an engineer runs `kill -9 <PID>`, the signal **bypasses the target process completely**. The Linux kernel abruptly destroys the process memory space.

**Consequences of premature `kill -9`:**
1. **Data Corruption**: Unwritten memory buffers are never flushed to disk.
2. **Stale Lock Files**: Files like `/var/run/app.pid` or `/tmp/app.lock` are left behind, preventing the service from restarting.
3. **Leaked Network Connections**: TCP sockets remain in half-open states (`FIN_WAIT`) until timeout.
4. **Child Process Orphanage**: Subprocesses may continue running detached without coordination.

> [!IMPORTANT]
> **Best Practice Order of Escalation**:
> 1. Send `SIGTERM` (`kill <PID>`).
> 2. Wait 5 to 15 seconds for clean shutdown.
> 3. Only if the process remains hung in an unresponsive state, issue `SIGKILL` (`kill -9 <PID>`).

---

## 🧟 Zombie vs. Orphan Processes

### Orphan Process
- An **orphan** is a child process whose parent exited or crashed before the child finished.
- **Kernel Resolution**: The Linux kernel automatically re-parents orphaned processes to PID 1 (`systemd`). PID 1 regularly reaps terminated children. Orphans do not cause system degradation.

### Zombie Process (`defunct`)
- A **zombie** is a process that has called `exit()`, freed its memory and descriptors, but remains in the process table because its parent has **not yet called `wait()`**.
- **The Threat**: While zombies consume no CPU or memory, the Linux kernel has a fixed maximum number of PIDs (`/proc/sys/kernel/pid_max`, typically 32,768 or 4,194,304). If a broken parent process leaks thousands of zombies, the system **runs out of PIDs**. Once exhausted, no new processes (including SSH connections, monitoring checks, or shell commands) can be spawned (`fork: Cannot allocate memory`).

```bash
# Identify zombie processes
ps aux | grep 'Z'
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'

# You CANNOT kill a zombie with 'kill -9' (it is already dead!).
# To eliminate a zombie, kill or restart its PARENT process (PPID):
kill -15 <PPID>
```

---

# Day 16 Hands-On Drill: CPU Stress & Signal Termination

### Step 1: Inspect System Load & Top Consumers
```bash
# View live interactive metrics
top
# Or install modern htop
sudo apt install -y htop && htop
```

### Step 2: Spawn a Background Stress Process
```bash
# Spawn a tight CPU loop in the background and capture its PID
sh -c 'while true; do :; done' &
STRESS_PID=$!
echo "Spawned stress loop with PID: $STRESS_PID"
```

### Step 3: Verify Process Under Top
```bash
# Check process CPU usage and state
ps -p "$STRESS_PID" -o pid,ppid,%cpu,stat,comm
```

### Step 4: Gracefully Terminate via SIGTERM
```bash
kill -15 "$STRESS_PID"
# Verify termination
kill -0 "$STRESS_PID" 2>/dev/null || echo "Process $STRESS_PID cleanly terminated."
```

---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Kernel PID Exhaustion Caused by Zombie Leak in Legacy Microservice
- **Symptom / Alert**: Critical P1 incident. Engineers could no longer SSH into a production node (`fork: Cannot allocate memory`). Monitoring reported 90% free RAM and 15% CPU load.
- **Investigation & Triage**:
  - Existing open root console session showed:
    ```bash
    $ ps aux | wc -l
    32760
    ```
  - Inspected process status flags:
    ```bash
    $ ps -eo stat,comm | grep -c "Z"
    31840
    ```
    Over 31,000 processes were in `Z` (Zombie/Defunct) state.
  - Checked parent PID of the zombies:
    ```bash
    $ ps -eo ppid,stat,comm | grep "Z" | head -n 5
    1402 Z [worker] <defunct>
    1402 Z [worker] <defunct>
    ```
- **Root Cause Analysis (RCA)**: Process ID `1402` was a custom Python API worker that spawned subprocesses to handle incoming image transformations. The developer omitted the `os.wait()` / `process.wait()` handler. When workers terminated, their exit codes were never collected, leaking a zombie entry in the kernel table for every API request until the system reached `pid_max` (32,768).
- **Remediation & Fix**:
  - Sent `SIGTERM` to the buggy parent process (`kill -15 1402`). PID 1 adopted the orphaned zombies and immediately purged them from the kernel table.
  - Available PIDs recovered instantly from 8 to 31,000+.
  - Patched application code to use Python's `with subprocess.Popen(...)` context manager with proper `.wait()` and reaping logic.
- **Engineering Takeaway**: Zombies cannot be killed directly because they are already dead; the parent process must be fixed or restarted. Always monitor `process_count` and `zombie_count` in server alerting systems.
