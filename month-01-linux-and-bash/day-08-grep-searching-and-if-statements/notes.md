# The Complete `grep` Reference Guide

## 🚩 Flag Reference Table

| Flag | Name | Function | Practical Example |
|:---:|---|---|---|
| `-i` | Ignore Case | Case-insensitive search (`ERROR`, `error`, `Error`). | `grep -i "error" /var/log/syslog` |
| `-r` | Recursive | Searches all files across subdirectories. | `grep -r "database_url" /var/www/` |
| `-n` | Line Numbers | Prints line number of match within the file. | `grep -n "listen" /etc/nginx/nginx.conf` |
| `-w` | Whole Word | Matches exact words only (won't match `logging` if searching `log`). | `grep -w "log" app.conf` |
| `-v` | Invert Match | Excludes matching lines (returns everything else). | `grep -v "^#" /etc/ssh/sshd_config` *(strips comments)* |
| `-c` | Count | Returns count of matching lines instead of content. | `grep -c "Failed" /var/log/auth.log` |
| `-E` | Extended Regex | Enables `+`, `?`, `|`, and grouping without escaping. | `grep -E "404|500" access.log` |

---

## 🔣 Essential Regular Expression Anchors

| Pattern | Meaning | Example | What it matches |
|:---:|---|---|---|
| `^` | Start of line | `^ubuntu` | Lines that begin with `ubuntu`. |
| `$` | End of line | `false$` | Lines that end with `false`. |
| `^$` | Empty line | `grep -v "^$"` | Filters out all blank lines. |
| `.` | Any single character | `b.sh` | Matches `bash`, `bosh`, `bush`. |
| `*` | Zero or more of previous | `ab*c` | Matches `ac`, `abc`, `abbc`. |

---

## 🏆 Day 08 Challenge Solution:
```bash
grep -rni "ssh" /etc/ 2>/dev/null
```


---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Premature Script Abort with `grep` Under `set -e`
- **Symptom / Alert**: A health-check script abruptly crashed halfway through execution with zero error message.
- **Investigation & Triage**:
  1. Added debug tracing: `bash -x health_check.sh`.
  2. Script halted at line: `grep -i "CRITICAL" /var/log/app.log`.
  3. Checked exit code of grep when no "CRITICAL" entries exist: `$? == 1`.
- **Root Cause Analysis (RCA)**: When `set -e` (exit on error) is active, `grep` returning exit code 1 (indicating "no matching lines found") is interpreted by the shell as a fatal error, triggering an instant script abort.
- **Remediation & Fix**:
  - Wrapped grep check in conditional syntax:
    ```bash
    if grep -q "CRITICAL" /var/log/app.log; then
      notify_pager
    else
      echo "System healthy: 0 critical events found."
    fi
    ```
- **Engineering Takeaway**: In Bash scripts running with `set -e`, handle standard non-zero exit statuses (such as `grep` returning 1 for no match) explicitly.
