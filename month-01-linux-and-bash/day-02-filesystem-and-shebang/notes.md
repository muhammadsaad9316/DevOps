# Day 02 Notes: Paths, Special Shortcuts & The `./` Security Model

## 🧭 Special Directory Symbols

| Symbol | Meaning | Example Command | Description |
|:---:|---|---|---|
| `.` | Current Working Directory | `./script.sh` | References the exact directory you are currently in. |
| `..` | Parent Directory (one level up) | `cd ..` | Navigates up one tier in the hierarchy. |
| `~` | Current User's Home Directory | `cd ~` | Expands to `/home/<username>` (or `/root`). |
| `/` | Root Directory of the filesystem | `cd /` | The apex of the entire Linux filesystem hierarchy. |
| `-` | Previous Working Directory | `cd -` | Toggles back to where you were before the last `cd`. |

---

## 🔒 Why is `./` Required to Run a Local Script?

When you type a command like `ls` or `date`, the shell does not search the current directory. Instead, it searches the directories listed in your **`$PATH` environment variable**:

```bash
echo $PATH
# Output: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### The Security Vulnerability Solved by `./`:
If the current directory (`.`) were inside `$PATH`, an attacker or malicious user could place an executable named `ls` inside `/tmp` or a shared directory:
```bash
# Evil script in /tmp:
cat << 'EOF' > /tmp/ls
#!/bin/bash
rm -rf /important_data
EOF
```
If an administrator entered `/tmp` and typed `ls`, the attacker's script would execute with admin privileges!

**By requiring explicit pathing (`./script.sh`), Linux guarantees that you only run local scripts intentionally.**


---

# `ls -l` Output Breakdown: Column by Column

When you run `ls -lah`, an output line looks like this:

```text
drwxr-xr-x  4  ubuntu  developers  4096  Sep 18 01:30  projects
-rw-r--r--  1  ubuntu  ubuntu       220  Sep 18 01:25  hello.sh
```

| Column | Example | Technical Meaning |
|---|---|---|
| **1. File Type & Permissions** | `-rw-r--r--` | First character: `-` (file), `d` (directory), `l` (symlink). Next 9 chars: User/Group/Others `rwx` permissions. |
| **2. Hard Link Count** | `1` (or `4`) | Number of hard links pointing to this inode. Directories have at least 2 (`.` and parent entry). |
| **3. Owner** | `ubuntu` | User account that owns the resource. |
| **4. Group** | `developers` | Group associated with the resource. |
| **5. Size (Bytes)** | `4096` / `220` | Size of file in bytes (or human-readable `4.0K` when `-h` is passed). |
| **6. Last Modified Timestamp** | `Sep 18 01:25` | Date and time the file was last written to. |
| **7. File/Directory Name** | `hello.sh` | Name of the file or directory. |

---

## 🛠️ Essential `ls` Flags

| Flag | Purpose | Command Example |
|---|---|---|
| `-l` | Long listing format (permissions, owner, size). | `ls -l` |
| `-a` | Shows hidden files (files starting with a dot `.`). | `ls -a` |
| `-h` | Human-readable file sizes (`K`, `M`, `G`). | `ls -lh` |
| `-R` | Recursively lists all subdirectories. | `ls -R` |
| `-t` | Sorts files by modification time (newest first). | `ls -lt` |
| `-r` | Reverses whatever sort order is applied. | `ls -ltr` |


---

# Day 02 Hands-On Navigation Drills

## Drill 1: The One-Command Jump
**Objective**: From any arbitrary deep directory (e.g. `/etc/systemd/system`), return to `/var/log` in exactly one command:
```bash
# Absolute Jump:
cd /var/log

# Relative Jump from /etc/systemd/system:
cd ../../../var/log
```

---

## Drill 2: Tree Visualization
Inspect the directory shape without GUI:
```bash
# Install tree
sudo apt update && sudo apt install -y tree

# Print top 2 levels of /etc
tree -L 2 /etc
```

---

## Drill 3: Hidden Files Discovery
Compare `ls` vs `ls -a` in your user home directory:
```bash
cd ~
ls      # Notice config dotfiles are hidden
ls -la  # Notice .bashrc, .profile, .ssh are now visible
```
