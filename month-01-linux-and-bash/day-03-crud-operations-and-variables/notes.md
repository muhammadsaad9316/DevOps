# Day 03 Notes: CRUD Operations & Shell Variable Expansion

## ⚠️ The Danger of `rm` in Linux: How Unlinking Works

In the Linux ext4/xfs filesystem:
1. Every file consists of an **inode** (storing metadata, size, permissions, and block pointers) and **data blocks** (storing file content).
2. A filename in a directory is merely a hard link pointing to an inode number.
3. When you run `rm filename`, the system calls `unlink()`. It removes the directory pointer and decrements the inode's link count.
4. When link count reaches zero and no open process has the file descriptor open, the operating system marks those data blocks as free space immediately.

> [!WARNING]
> There is **no Recycle Bin** or Trash buffer on the command line. Data recovery requires specialized forensic tools or backups. Never run `rm -rf /` or `rm -rf /*`.

---

## 💬 Bash Quoting Rules

| Quote Type | Behavior | Example | Output |
|---|---|---|---|
| **Double Quotes (`"`)** | **Weak Quoting**: Allows variable expansion (`$VAR`), command substitution (`$(cmd)`), and arithmetic expansion (`$(( ))`). Preserves literal spaces. | `echo "User: $USER"` | `User: ubuntu` |
| **Single Quotes (`'`)** | **Strong Quoting**: Treats every character inside strictly as a literal string. Disables all expansion. | `echo 'User: $USER'` | `User: $USER` |
| **Backticks / `$( )`** | **Command Substitution**: Executes the inner command and replaces with its output. | `echo "Date: $(date +%F)"` | `Date: 2026-09-18` |

---

## 🚫 The Bash Syntax Rule: No Spaces Around `=`
```bash
# Correct:
APP_ENV="production"

# Syntax Error / Bug:
APP_ENV = "production"   # Tries to execute a command named 'APP_ENV' with arguments '=' and 'production'
```


---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Wildcard Unlink Collision & Permanent Data Loss
- **Symptom / Alert**: Running `rm *.log` inside an application directory unexpectedly deleted critical audit logs that had not been backed up.
- **Investigation & Triage**:
  1. Checked shell command history: `history | tail -n 5`.
  2. Found command executed was `rm -rf *.log` from the root of the project directory rather than `./tmp/logs/`.
- **Root Cause Analysis (RCA)**: Bash expands wildcards (`*`) *before* executing the command. Combined with `rm`, there is no confirmation prompt and no recycling buffer. Ext4 unlinks inodes immediately.
- **Remediation & Fix**:
  - Implemented strict command hygiene: Always run `ls *.log` or `echo *.log` first to verify the target list before executing destructive deletion commands.
  - Added alias protection in `.bashrc`: `alias rm='rm -i'` for interactive sessions.
- **Engineering Takeaway**: In production automation, never use unconstrained wildcards with `rm`. Use `find /target/path -name "*.log" -mtime +30 -delete` with explicit boundary constraints.
