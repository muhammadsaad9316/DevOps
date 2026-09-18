# Standard Streams & I/O Redirection Architecture

## 🔌 Standard File Descriptors

Every process started in Linux automatically inherits three standard file descriptors:

| Descriptor | Name | Default Device | Redirection Operator |
|:---:|---|---|---|
| **`0`** | `stdin` (Standard Input) | Keyboard | `<` (read from file) |
| **`1`** | `stdout` (Standard Output) | Terminal Screen | `>`, `>>` |
| **`2`** | `stderr` (Standard Error) | Terminal Screen | `2>`, `2>>` |

---

## 🔄 Redirection Operators

```bash
# 1. Overwrite stdout
echo "version 1.0" > app.log

# 2. Append to stdout
echo "version 1.1" >> app.log

# 3. Redirect stderr only
ls /nonexistent 2> errors.log

# 4. Redirect stdout and stderr to separate files
command > output.log 2> errors.log

# 5. Combine stdout and stderr into one destination
command > combined.log 2>&1
# (Modern Bash shortcut):
command &> combined.log

# 6. Discard all output completely into the virtual bit-bucket
command > /dev/null 2>&1
```

---

## 🚰 Multiplexing with `tee`
```text
           [ Process stdout ]
                   |
                [ tee ]
               /       \
              v         v
     [ Terminal Screen ]  [ logfile.txt ]
```
```bash
echo "Deployment started" | tee -a deployment.log
```


---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Unattended Cron Job Hanging Indefinitely on stdin
- **Symptom / Alert**: Nightly maintenance cron job remained running for 14 hours, locking system resources.
- **Investigation & Triage**:
  1. Ran `ps aux | grep maintenance.sh` and checked process state (`S` - sleeping).
  2. Inspected open file descriptors: `sudo lsof -p <PID>` showed descriptor 0 (`stdin`) open and waiting for user input.
- **Root Cause Analysis (RCA)**: A sub-command inside the script was called without an argument, causing it to fall back to interactive stdin input. Since cron runs headless without an interactive terminal, the process hung waiting for an EOF that never came.
- **Remediation & Fix**:
  - Explicitly closed standard input for background execution: `exec 0</dev/null`.
  - Redirected cron entry: `0 2 * * * /opt/scripts/maintenance.sh </dev/null >/var/log/maint.log 2>&1`.
- **Engineering Takeaway**: All automated non-interactive tasks and daemons must have standard input (`stdin`) explicitly redirected from `/dev/null`.
