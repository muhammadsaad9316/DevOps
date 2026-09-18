# Day 07 Notes: Exit Codes ($?) & Automation Architecture

## 🚦 The Universal Linux Exit Code Standard

Every Linux command or process returns an integer exit status (between `0` and `255`) upon termination:

| Exit Code | Meaning | Interpretation |
|:---:|---|---|
| **`0`** | **Success** | The command completed with zero errors. |
| **`1`** | **General Error** | Catch-all for general application/runtime errors. |
| **`2`** | **Misuse of Shell Builtin** | Missing keyword or syntax error in shell command. |
| **`126`** | **Command Cannot Execute** | Permission problem or command is not an executable binary. |
| **`127`** | **Command Not Found** | Binary is not found anywhere in `$PATH`. |
| **`130`** | **Script Terminated via SIGINT** | Process was killed by `Ctrl + C`. |

---

## 🏗️ Why Exit Codes Govern Automated CI/CD Pipelines

In automation systems (GitHub Actions, GitLab CI, Kubernetes readiness probes, Ansible):
1. The orchestrator executes each script in non-interactive mode.
2. The orchestrator cannot "read" human-friendly text output to guess if a step succeeded.
3. Instead, it reads `$?`:
   - If `$? == 0`, it proceeds to the next build/deploy stage.
   - If `$? != 0`, the pipeline immediately aborts and triggers failure alerts.

```bash
# In Bash automation:
cp config.prod.json config.json
if [ $? -ne 0 ]; then
  echo "Critical: Failed to copy production config! Aborting deployment." >&2
  exit 1
fi
```
*(In modern bash scripts, `set -e` automatically aborts if any command fails).*


---

# The Master `find` Cheatsheet

## Syntax
```bash
find [search_path] [flags / criteria] [action]
```

---

## 🔍 Common Search Criteria

| Requirement | Command Example |
|---|---|
| **By Exact/Pattern Name** | `find /etc -name "*.conf"` |
| **Case-Insensitive Name** | `find /var/log -iname "*.log"` |
| **By File Type** | `find /var -type f` *(files only)*, `find /etc -type d` *(dirs only)* |
| **By Size (> 10MB)** | `find / -type f -size +10M 2>/dev/null` |
| **By Size (< 1KB)** | `find /var/log -type f -size -1k` |
| **Modified in last 2 days** | `find /etc -mtime -2` |
| **Modified over 30 days ago** | `find /tmp -mtime +30` |
| **Empty files or folders** | `find /tmp -empty` |
| **By Permissions** | `find / -perm 777 2>/dev/null` |

---

## ⚡ Taking Action with `-exec`

```bash
# Run command per file (less efficient):
find /var/log -name "*.log" -exec gzip {} \;

# Run command in batch mode (passes all matching files as arguments at once):
find /etc -name "*.conf" -exec ls -lh {} +
```

---

## 🏆 Challenge: 5 Largest Files in `/var`
```bash
sudo find /var -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 5
```
*(Or using `ls`: `sudo find /var -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -rh | head -n 5`)*
