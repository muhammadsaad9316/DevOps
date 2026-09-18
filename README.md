# 🐧 DevOps & Linux Engineering Roadmap

> A disciplined, production-grade repository documenting daily hands-on engineering labs, system administration notes, and automation scripts.

---

## 🧭 Repository Structure

```text
.
├── Devops/                                 # Raw curriculum roadmap specifications
├── month-01-linux-and-bash/                # Month 1: Linux Fundamentals & Bash Companion
│   ├── day-01-first-contact-and-scripting/
│   ├── day-02-filesystem-and-shebang/
│   ├── day-03-crud-operations-and-variables/
│   ├── day-04-file-reading-and-command-substitution/
│   ├── day-05-offline-help-and-user-input/
│   ├── day-06-filesystem-hierarchy-and-arguments/
│   ├── day-07-finding-files-and-exit-codes/
│   ├── day-08-grep-searching-and-if-statements/
│   ├── day-09-pipes-redirection-and-test-conditions/
│   ├── day-10-text-processing-and-arithmetic/
│   ├── day-11-users-groups-and-for-loops/
│   ├── day-12-permissions-matrix-and-loop-audits/
│   ├── day-13-ownership-umask-and-while-loops/
│   └── day-14-sudo-privileges-and-case-menus/
└── README.md                               # Root roadmap index & progress tracker
```

---

## 📊 Month 1: Linux & Bash Foundations (Days 1–14 Progress)

| Day | System Core (Linux Fundamentals) | Automation Companion (Bash Scripting) | Status |
|:---:|---|---|:---:|
| **01** | First Contact: VM Provisioning, Terminal & Commands | First Script: Shebang, Echo, Comments | ✅ Ready |
| **02** | Filesystem Navigation: Inodes, Relative/Absolute Paths | Execution Rights: `chmod +x`, Why `./` is needed | ✅ Ready |
| **03** | CRUD Operations: Directories, Safe File Deletion | Variables: Assignment, Quoting Rules (`"` vs `'`) | ✅ Ready |
| **04** | File Inspection: Streaming, Paginated Viewers, Vim survival | Command Substitution: `$(...)` and dynamic timestamps | ✅ Ready |
| **05** | Offline Discovery: `man` sections, `--help`, `apropos` | Interactive Input: `read -p` and prompt validation | ✅ Ready |
| **06** | Filesystem Hierarchy Standard (FHS): System layout | Positional Parameters: `$1`, `$#`, CLI arguments | ✅ Ready |
| **07** | Deep File Discovery: `find`, `which`, disk usage | Exit Codes: `$?`, `exit 1`, Pipeline reliability | ✅ Ready |
| **08** | Pattern Matching: `grep` flags, regex, log triage | Conditional Logic: `if/else`, file guards | ✅ Ready |
| **09** | I/O Redirection: `stdout`, `stderr`, pipes, `/dev/null` | Test Operators: `[ -f ]`, `[ -d ]`, string tests | ✅ Ready |
| **10** | Text Processing: `sort`, `uniq`, `cut`, pipelines | Numbers & Arithmetic: `$(( ))`, integer comparison | ✅ Ready |
| **11** | Multi-User Security: `/etc/passwd`, `/etc/shadow`, UIDs | The `for` Loop: Iteration, file globs, batch renames | ✅ Ready |
| **12** | Permissions Matrix: Octal/Symbolic modes, directory `x` | Loop-Based Auditing: Permission checking scripts | ✅ Ready |
| **13** | Ownership & umask: `chown`, `umask`, special bits | The `while` Loop: Line-by-line file parsing | ✅ Ready |
| **14** | Privilege Escalation: `sudo`, `visudo`, least privilege | Structural Branching: `case` statements, CLI menus | ✅ Ready |

---

## 🛠️ How to Use This Repository

1. **Navigate into a specific day**: Each folder contains a self-contained `README.md` outlining the curriculum tasks, technical notes, and verification drills.
2. **Execute scripts**: Ensure scripts have execution permissions:
   ```bash
   chmod +x ./path/to/script.sh
   ./path/to/script.sh
   ```
3. **Commit your work**: As you complete hands-on labs in your VM, record your findings in the respective day's `notes.md` and commit:
   ```bash
   git add .
   git commit -m "feat(day-X): complete lab exercises and documentation"
   git push origin main
   ```
