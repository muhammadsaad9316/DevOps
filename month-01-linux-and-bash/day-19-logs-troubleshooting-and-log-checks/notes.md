# Day 19: Linux Logging Architecture, Journald Forensic Triage & Log Automation

## 🧠 Linux Logging Architecture: `systemd-journald` & `rsyslog`

In production Linux infrastructure, system telemetry and application output are captured, indexed, and rotated by two cooperating subsystems: **`systemd-journald`** and **`rsyslog`** (or logrotate).

```text
 ┌───────────────────────┐   ┌───────────────────────┐   ┌───────────────────────┐
 │ Standard System Units │   │ Kernel Ring (dmesg)   │   │ App stdout / stderr   │
 └───────────┬───────────┘   └───────────┬───────────┘   └───────────┬───────────┘
             │                           │                           │
             └───────────────────────────┼───────────────────────────┘
                                         ▼
                             ┌───────────────────────┐
                             │   systemd-journald    │
                             │ (Binary, Indexed Log) │
                             └───────────┬───────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
     ┌────────────────────────┐                      ┌────────────────────────┐
     │ journalctl CLI Query   │                      │ Forward to /var/log/*  │
     │ Fast, Structured, Rich │                      │ (rsyslog / logrotate)  │
     └────────────────────────┘                      └────────────────────────┘
```

### 1. How `systemd-journald` Works
- When any daemon or process supervised by systemd writes to standard output (`stdout`) or standard error (`stderr`), the kernel redirects the output directly into `systemd-journald` via a UNIX domain socket (`/run/systemd/journal/stdout`).
- Unlike traditional plain-text log files, journald writes logs in a **binary, indexed, and cryptographically verified format**.
- **Ephemeral vs Persistent Storage**:
  - By default on minimal systems, logs reside in volatile RAM under `/run/log/journal/` (lost on reboot).
  - To make logs persistent across reboots, create `/var/log/journal/` or configure `Storage=persistent` in `/etc/systemd/journald.conf`.

---

## ⚡ Master `journalctl` Command Matrix

`journalctl` is an SRE's primary forensic lens. Knowing how to filter without generating huge terminal dumps is an essential production competency:

| Task / Objective | Command | Real-World Operational Context |
|---|---|---|
| **View entire log with pager** | `journalctl` | Opens inside `less`. Use `/pattern` to search, `q` to exit. |
| **Jump to end of log** | `journalctl -e` | Skips historical boot logs and jumps to the most recent entries. |
| **Filter by single unit** | `journalctl -u nginx.service` | Isolates all output produced by Nginx master and workers. |
| **Follow log live** | `journalctl -f -u nginx` | Continuously streams new log events (like `tail -f`). |
| **Filter by time window** | `journalctl --since "1 hour ago"` | Scopes triage during a known incident window. |
| **Bounded time window** | `journalctl --since "04:00" --until "04:30"` | Isolates logs to a specific deployment maintenance window. |
| **Filter by severity** | `journalctl -p err..emerg` | Shows only errors, critical conditions, alerts, and emergencies. |
| **Show catalog explanations** | `journalctl -xeu nginx` | Displays verbose diagnostics, man page links, and error hints. |
| **Filter by current boot** | `journalctl -b` | Hides previous boots; focuses on current VM uptime. |
| **Kernel messages only** | `journalctl -k` | Displays hardware/driver faults and kernel panics (dmesg). |
| **Output as JSON** | `journalctl -u nginx -o json-pretty` | Structured data for automated parsing in monitoring agents. |

### Severity Levels (Syslog Priority Standard: 0 to 7)
```text
0 = Emergency (System unusable)
1 = Alert (Action must be taken immediately)
2 = Critical (Critical conditions)
3 = Error (Error conditions)
4 = Warning (Warning conditions)
5 = Notice (Normal but significant condition)
6 = Informational (Informational messages)
7 = Debug (Debug-level messages)
```

---

## 🛡️ Log Rotation Deep Dive: Why Logs Do Not Fill the Disk Forever

Without log rotation, high-throughput web servers generating millions of HTTP requests would consume 100% of the disk within days. The Linux **`logrotate`** utility automates archiving, compression, truncation, and deletion based on configurable retention schedules.

### 1. Architecture of `logrotate`
- `logrotate` is run daily via a systemd timer (`logrotate.timer`) or cron (`/etc/cron.daily/logrotate`).
- Global settings are defined in `/etc/logrotate.conf`.
- Service-specific configurations reside in modular files inside `/etc/logrotate.d/` (e.g. `/etc/logrotate.d/nginx`, `/etc/logrotate.d/rsyslog`).

### 2. Dissecting `/etc/logrotate.d/nginx`

```ini
/var/log/nginx/*.log {
    daily               # Rotate log files once every 24 hours
    missingok           # Do not throw an error if the log file is missing
    rotate 14           # Keep 14 rotated archives before deleting the oldest
    compress            # Compress rotated files using gzip (.gz)
    delaycompress       # Wait until the next rotation cycle before compressing .1
    notifempty          # Do not rotate empty files (saves inode and CPU cycles)
    create 0640 www-data adm # Create new empty log with exact permissions
    sharedscripts       # Run postrotate script once, not once per matched file
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}
```

### Why `kill -USR1` (or Reopening File Descriptors)?
Linux processes write to open **file descriptors**, not file names. If `logrotate` renames `access.log` to `access.log.1`, Nginx continues writing into the renamed file! The `postrotate` script sends signal **`USR1`** to the master process, commanding it to reopen its log file handles and begin writing to the newly created `access.log`.

---

## 🛠️ Hands-On Drills: Logging & Troubleshooting

### Drill 1: Navigating and Paging with `journalctl`
```bash
# 1. Open system journal in less pager
journalctl

# Paging Navigation:
# - Press 'Shift + G' to jump to bottom (latest events)
# - Press 'g' to jump to top (oldest events)
# - Type '/failed' and press Enter to search forward
# - Press 'n' to find next match, 'N' for previous
# - Press 'q' to quit pager
```

### Drill 2: Service Isolation & Live Following
```bash
# Terminal 1: Stream Nginx logs live
journalctl -f -u nginx

# Terminal 2: Trigger service restart in another window
sudo systemctl restart nginx

# Observe Terminal 1: Watch systemd stop workers, start master, and acknowledge healthy status in real-time!
```

### Drill 3: Scoping Forensic Window by Time
```bash
# View all logs generated in the last 30 minutes
journalctl --since "30 minutes ago"

# View logs between specific hours
journalctl --since "2026-09-24 04:00:00" --until "2026-09-24 05:00:00"
```

### Drill 4: Blind Bug Hunt - Isolating Nginx Errors Without Asking
```bash
# 1. Inject an invalid directive in nginx configuration
echo "proxy_buffer_unlimited_broken on;" | sudo tee -a /etc/nginx/sites-available/default

# 2. Attempt restart and observe failure
sudo systemctl restart nginx
# Job for nginx.service failed.

# 3. Discover exact root cause using journalctl -xeu
journalctl -xeu nginx --no-pager | tail -n 20
# Notice the clear error message:
# "unknown directive 'proxy_buffer_unlimited_broken' in /etc/nginx/sites-available/default:..."

# 4. Remove corrupt directive and verify recovery
sudo sed -i '/proxy_buffer_unlimited_broken/d' /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl restart nginx
```

### Drill 5: Testing `logrotate` Configurations
```bash
# Test /etc/logrotate.d/nginx in debug dry-run mode (does not modify disk)
sudo logrotate -d /etc/logrotate.d/nginx

# Force immediate execution of rotation
sudo logrotate -f /etc/logrotate.d/nginx
ls -lh /var/log/nginx/
```

---

## 🤖 Defensive Bash: Scripting Log Checks & Threshold Alerts

In automated SRE pipelines, polling logs and raising alarms must be fast, accurate, and non-blocking:

### Why Use `grep -c` Over Looping?
- Looping over log lines in Bash is extremely slow (O(N) subshell forks).
- `grep -c "PATTERN" file.log` delegates pattern matching to optimized C SIMD code in the GNU grep binary, returning an exact integer count in milliseconds.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/nginx/error.log"
PATTERN="connect() failed"
WARN_THRESHOLD=5

# Count matches safely (grep -c exits with 1 if count is 0, so handle defensively)
COUNT=$(grep -c "$PATTERN" "$LOG_FILE" 2>/dev/null || true)
COUNT=${COUNT:-0}

if [[ "$COUNT" -ge "$WARN_THRESHOLD" ]]; then
    echo "[WARNING] Found ${COUNT} upstream connection errors in ${LOG_FILE}!"
    exit 1
else
    echo "[OK] Error count (${COUNT}) within acceptable limits (< ${WARN_THRESHOLD})."
    exit 0
fi
```

### Preventing Alert Fatigue
A monitoring script that alerts on *every single error* will be muted by on-call engineers. Real SRE monitoring pairs count thresholds with time-windowing or rate thresholds (e.g., > 10 errors within 5 minutes).

---

## 🚨 SRE Incident Post-Mortem

### Case Study: Production Outage Caused by Unrotated Access Logs Exhausting Disk Space and Inodes
- **Severity**: P1 Critical (Core Transaction Database Frozen, API Gateways Dropping Connections).
- **Incident Summary**: At 06:14 UTC, a high-volume payment processing cluster stopped accepting transactions. Health checks across all services reported HTTP 500. Disk monitoring fired a critical alert: `/var/log` on host `srv-ingress-02` had reached **100% capacity (0 bytes free)**.
- **Triage & Investigation**:
  1. `df -h` confirmed `/dev/sda1` was 100% full.
  2. `df -i` confirmed inode exhaustion.
  3. `du -sh /var/log/* | sort -hr | head -n 5` revealed:
     `/var/log/nginx/access.log` was **184 Gigabytes**.
  4. Investigation into `/etc/logrotate.d/nginx` revealed an engineer had commented out the rotation configuration during a previous debugging session and forgot to revert it.
  5. Because the file system was completely full, PostgreSQL failed to write write-ahead logs (`WAL`) and placed itself in emergency read-only mode to prevent data corruption.
  6. `systemd-journald` was dropping incoming log messages due to write buffer exhaustion.
- **Remediation & Preventative Action**:
  1. **Immediate Triage**: Safely truncated the run-away log file using `: > /var/log/nginx/access.log` (avoiding `rm` which would have left the file space held open by the active Nginx file descriptor).
  2. Sent `USR1` signal to Nginx master process to reopen file handles.
  3. Restored `/etc/logrotate.d/nginx` with daily rotation, gzip compression, and max file size ceiling (`maxsize 500M`).
  4. Installed an automated sentinel script (`log_alert_sentinel.sh`) in cron to alert ops whenever any single log file exceeds 5GB.
