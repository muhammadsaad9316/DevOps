# Day 18: Systemd Architecture, Service Supervision & Safe Bash Automation

## 🧠 Linux Init Systems & Systemd Architecture

In modern Linux distributions (Ubuntu 16.04+, Debian 8+, RHEL/CentOS 7+), **`systemd`** serves as the init system and service manager. Assigned **PID 1**, it is the direct ancestor of all user-space processes and the first program executed by the Linux kernel after bootstrapping.

```text
                           ┌────────────────────────┐
                           │      Linux Kernel      │
                           └───────────┬────────────┘
                                       │ Launches PID 1
                                       ▼
                           ┌────────────────────────┐
                           │   systemd (PID 1)      │
                           │ • Socket Activation    │
                           │ • CGroup Resource Mgmt │
                           │ • Dependency Engine    │
                           └───────────┬────────────┘
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│  Target Units    │          │  Service Units   │          │  Timer Units     │
│ multi-user.target│          │  nginx.service   │          │  logrotate.timer │
└──────────────────┘          └──────────────────┘          └──────────────────┘
```

### Why Systemd Replaced SysVinit
1. **Parallel Execution**: Legacy SysVinit executed shell scripts in `/etc/init.d/` sequentially (slow, blocking boot times). Systemd constructs a directed acyclic graph (DAG) of dependencies and launches independent services simultaneously.
2. **Deterministic Process Tracking with CGroups**: Under SysVinit, double-forking daemons could orphan processes, leaving stale workers when a parent crashed. Systemd places every service into its own Linux **Control Group (cgroup)**, guaranteeing complete process tree accounting and clean SIGTERM/SIGKILL termination.
3. **Socket & D-Bus Activation**: Daemons can be launched on-demand only when incoming network traffic or IPC messages arrive on a listening socket.
4. **Unified Journaling**: Standard output and error streams from supervised daemons are captured automatically by `systemd-journald`.

---

## 🗂️ Unit File Storage Hierarchy & Precedence

Systemd locates unit files (services, timers, targets, sockets) across three primary directory tiers. Understanding their precedence is vital for configuration overrides:

```text
Priority 1 (Highest) : /etc/systemd/system/     [Admin Overrides & Custom Services]
Priority 2 (Medium)  : /run/systemd/system/     [Runtime Ephemeral Units (RAM)]
Priority 3 (Lowest)  : /lib/systemd/system/     [Packaged Vendor Defaults (/usr/lib)]
```

| Location | Purpose | Who Manages It? | Overwrites on Package Upgrade? |
|---|---|---|---|
| **`/etc/systemd/system/`** | Custom units, symlinks for enabled targets, drop-in overrides (`service.d/*.conf`). | System Administrator / SRE | **No** (Safe for custom changes) |
| **`/run/systemd/system/`** | Volatile units generated at boot or runtime by generators. | Linux Kernel / Dynamic Generators | **Yes** (Lost upon reboot) |
| **`/lib/systemd/system/`** (or `/usr/lib/`) | Default unit definitions packaged by Debian/Ubuntu APT. | Package Maintainer (`apt`) | **Yes** (Overwritten during updates) |

> 💡 **Best Practice**: Never edit `/lib/systemd/system/nginx.service` directly! Instead, run `sudo systemctl edit nginx` to create a drop-in override in `/etc/systemd/system/nginx.service.d/override.conf`, or copy the file to `/etc/systemd/system/` to shadow the default.

---

## 🔍 Dissecting `systemctl status nginx` Line by Line

When running `systemctl status nginx`, Systemd outputs rich real-time metadata. Every field has operational significance:

```text
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2026-09-24 05:00:00 UTC; 1h 25min ago
       Docs: man:nginx(8)
    Process: 41201 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 41202 (nginx)
      Tasks: 3 (limit: 4614)
     Memory: 5.8M (peak: 6.2M)
        CPU: 42ms
     CGroup: /system.slice/nginx.service
             ├─41202 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             ├─41203 "nginx: worker process"
             └─41204 "nginx: worker process"

Sep 24 05:00:00 srv-prod-01 systemd[1]: Starting nginx.service - A high performance web server...
Sep 24 05:00:00 srv-prod-01 systemd[1]: Started nginx.service - A high performance web server.
```

### Forensic Breakdown

1. **`● nginx.service`**: The unit identifier and human-readable description.
2. **`Loaded: loaded (/lib/...; enabled; vendor preset: enabled)`**:
   - `loaded`: The unit file was parsed successfully into memory.
   - `enabled`: A symlink exists in `/etc/systemd/system/multi-user.target.wants/`, meaning it will automatically start at boot.
   - `vendor preset: enabled`: The distribution default state upon initial package installation.
3. **`Active: active (running) since ...`**:
   - `active (running)`: The primary daemon process is executing and healthy. Other possible states include:
     - `inactive (dead)`: Stopped cleanly.
     - `failed (Result: exit-code)`: Crashed or failed startup command.
     - `activating (start-pre)`: Currently executing pre-flight hooks.
     - `deactivating`: Orderly shutdown sequence in progress.
   - `since ... ; 1h 25min ago`: The exact boot timestamp and uptime duration.
4. **`Process: 41201 ExecStartPre=...`**: Shows pre-flight execution commands and their exit status (`status=0/SUCCESS`).
5. **`Main PID: 41202 (nginx)`**: The principal daemon process ID supervised by Systemd.
6. **`Tasks: 3 (limit: 4614)`**: Number of kernel threads currently running within this cgroup (1 master + 2 workers).
7. **`Memory: 5.8M`**: Real-time physical RAM utilization enforced and measured via cgroups.
8. **`CGroup: /system.slice/nginx.service`**: The complete hierarchical process containment. When you stop the service, Systemd kills all processes listed in this tree, preventing rogue worker leaks.
9. **Log Tail**: The most recent 2–10 log events extracted directly from `journald`.

---

## ⚡ Master Systemctl Command Matrix

| Command | Action Performed | Kernel / System Impact |
|---|---|---|
| **`sudo systemctl start nginx`** | Boots the unit into the active state. | Executes `ExecStart` command. |
| **`sudo systemctl stop nginx`** | Shuts down the service. | Sends `SIGTERM` (followed by `SIGKILL` if timeout expires). |
| **`sudo systemctl restart nginx`** | Complete stop followed by start. | Drops existing TCP connections; new PID allocated. |
| **`sudo systemctl reload nginx`** | Hot reloads configuration without stopping. | Sends `SIGHUP`; zero downtime; preserves active connections. |
| **`sudo systemctl enable nginx`** | Configures service to start at boot. | Creates symbolic link in `/etc/systemd/system/*.wants/`. |
| **`sudo systemctl disable nginx`** | Prevents service starting at boot. | Deletes symbolic link in `/etc/systemd/system/*.wants/`. |
| **`systemctl is-active nginx`** | Prints `active` or `inactive` / `failed`. | Non-zero exit code if not active (ideal for bash scripts). |
| **`systemctl is-enabled nginx`** | Checks boot enablement status. | Exits with 0 if enabled, 1 if disabled. |
| **`sudo systemctl daemon-reload`** | Reloads systemd configuration files. | Must be executed whenever any `.service` file is modified on disk. |

---

## 🏗️ Anatomy of a Production Systemd Unit File

A standard systemd unit file is split into three core sections:

```ini
[Unit]
Description=Enterprise Nginx HTTP & Reverse Proxy Daemon
Documentation=man:nginx(8) http://nginx.org/en/docs/
After=network-online.target remote-fs.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=10s
KillMode=mixed
Restart=on-failure
RestartSec=5s

# Security Sandbox Hardening Directives
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

### Directive Breakdown
- **`Type=forking`**: Indicates the `ExecStart` process will fork child processes and the original parent will exit once initialized. (Use `Type=simple` for modern foreground processes).
- **`ExecStartPre`**: Commands that MUST succeed before launching the main binary. If `nginx -t` fails, Systemd halts startup immediately.
- **`Restart=on-failure`**: Restarts the daemon automatically if it crashes with a non-zero exit code or uncaught signal (e.g. `SIGSEGV`).
- **`RestartSec=5s`**: Delay between crash and restart to avoid CPU thrashing.
- **`WantedBy=multi-user.target`**: Establishes the dependency symlink when `systemctl enable` is invoked.

---

## 🛠️ Hands-On Drills: Systemd Mastery

### Drill 1: Install Nginx and Verify HTTP Availability
```bash
# 1. Install nginx web server
sudo apt update && sudo apt install -y nginx

# 2. Inspect initial systemd state
systemctl status nginx

# 3. Test HTTP connectivity locally
curl -I http://localhost/
# Expected: HTTP/1.1 200 OK
```

### Drill 2: Lifecycle Transitions (Start, Stop, Restart, Status)
```bash
# Stop service and observe status
sudo systemctl stop nginx
systemctl is-active nginx
# Output: inactive (exit code 3)

# Start service and verify recovery
sudo systemctl start nginx
systemctl is-active nginx
# Output: active (exit code 0)

# Reload configuration without dropping connections
sudo systemctl reload nginx
```

### Drill 3: Boot Persistence & Symlink Audit
```bash
# Disable boot auto-start and observe symlink deletion
sudo systemctl disable nginx
# Output: Removed /etc/systemd/system/multi-user.target.wants/nginx.service.

# Verify status
systemctl is-enabled nginx # Returns 'disabled'

# Re-enable and inspect created symlink
sudo systemctl enable nginx
# Output: Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service.
ls -l /etc/systemd/system/multi-user.target.wants/nginx.service
```

### Drill 4: Chaos Engineering - Break Configuration & Restore
```bash
# 1. Introduce syntax error in /etc/nginx/nginx.conf
echo "bad_directive_syntax;" | sudo tee -a /etc/nginx/nginx.conf

# 2. Attempt restart - Observe immediate failure
sudo systemctl restart nginx
# Job for nginx.service failed because the control process exited with error code.

# 3. Diagnose using systemctl
systemctl status nginx
# Shows: ExecStartPre ... status=1/FAILURE

# 4. Remove broken directive and recover
sudo sed -i '/bad_directive_syntax;/d' /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl restart nginx
systemctl is-active nginx # active
```

---

## 🤖 Defensive Bash: Scripting Service Supervision

When writing automation scripts to monitor or manage services, use `systemctl is-active --quiet`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE="nginx"

# 1. Check service status inside an if statement
if systemctl is-active --quiet "$SERVICE"; then
    echo "[OK] ${SERVICE} is active and healthy."
else
    echo "[WARN] ${SERVICE} is DOWN! Initiating safe restart..."
    
    # 2. Preflight syntax audit to avoid restarting a corrupt configuration
    if nginx -t >/dev/null 2>&1; then
        sudo systemctl restart "$SERVICE"
        echo "[RECOVERED] ${SERVICE} successfully restarted."
    else
        echo "[ABORT] Configuration syntax is corrupt. Manual intervention required." >&2
        exit 1
    fi
fi
```

---

## 🚨 SRE Incident Post-Mortem

### Case Study: Production API Gateway Outage Caused by Systemd Restart Thrashing & `start-limit-hit`
- **Severity**: P1 Major Outage (E-commerce Checkout Gateway Offline).
- **Incident Summary**: At 03:12 UTC, a high-traffic Nginx reverse proxy crashed due to temporary backend socket exhaustion. Because the unit file had `Restart=always` with **no `RestartSec` backoff**, Systemd attempted to restart Nginx hundreds of times per second. Systemd's internal circuit-breaker (`StartLimitBurst=5` within `StartLimitIntervalSec=10s`) triggered, permanently locking the service into a dead state (`Active: failed (Result: start-limit-hit)`). The gateway did not recover even after the backend restored.
- **Triage & Root Cause**:
  1. Inspection via `systemctl status nginx` revealed:
     `nginx.service: Start request repeated too quickly.`
     `nginx.service: Failed with result 'start-limit-hit'.`
  2. Because the restart rate was unbounded, Systemd assumed a catastrophic bug and refused further auto-restarts to protect the CPU.
  3. The on-call engineer had to manually execute `sudo systemctl reset-failed nginx` followed by `sudo systemctl start nginx`.
- **Remediation & Architectural Hardening**:
  1. Updated the unit override in `/etc/systemd/system/nginx.service.d/override.conf`:
     ```ini
     [Unit]
     StartLimitIntervalSec=300
     StartLimitBurst=5

     [Service]
     Restart=on-failure
     RestartSec=5s
     ```
  2. Added pre-flight health validation via `ExecStartPre` to prevent starting on bad configuration.
  3. Implemented synthetic heartbeat monitoring (`service_sentinel.sh`) to report service state and alert before circuit-breakers trip.
