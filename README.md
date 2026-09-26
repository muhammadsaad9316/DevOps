<div align="center">

# 🐧 Enterprise DevOps & Linux Engineering Roadmap

[![Ubuntu 24.04 LTS](https://img.shields.io/badge/Platform-Ubuntu%2024.04%20LTS-orange?logo=ubuntu&style=for-the-badge)](https://releases.ubuntu.com/24.04/)
[![Bash Scripting](https://img.shields.io/badge/Automation-Bash%205.2+-4EAA25?logo=gnu-bash&logoColor=white&style=for-the-badge)](https://www.gnu.org/software/bash/)
[![POSIX Compliant](https://img.shields.io/badge/Standard-POSIX%20Compliant-blue?style=for-the-badge)](https://pubs.opengroup.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

<p align="center">
  <b>A disciplined, production-grade engineering repository documenting daily hands-on labs, defensive shell scripting, Linux kernel architecture, and real-world SRE incident post-mortems.</b>
</p>

[Roadmap Overview](#-roadmap-overview) •
[Technical Competencies](#-core-technical-competencies) •
[Daily Labs & Incident Index](#-month-1-linux--bash-foundations-days-120) •
[Quick Start](#-quick-start--local-validation) •
[Author](#-author)

</div>

---

## 📌 Roadmap Overview

This repository represents a rigorous **9-month DevOps & Cloud Infrastructure engineering journey**, spanning from low-level Linux systems administration and defensive scripting to modern cloud architectures, CI/CD, and Kubernetes orchestration.

### 🗂️ Architectural Modules

```text
.
├── month-01-linux-and-bash/       # Month 1: Linux Kernel, Inodes, Permissions & Bash Automation
├── Devops/                        # Complete 9-month curriculum roadmap specifications
└── README.md                      # Primary engineering dashboard
```

---

## 🛠️ Core Technical Competencies Demonstrated

| Domain | Key Concepts & Tools | Real-World Application |
|---|---|---|
| **Linux Systems Administration** | FHS Standard, Inode mechanics, Systemd, Storage partitions, `/proc`, `/sys` | Production server hardening, VM provisioning, resource monitoring, capacity planning. |
| **Defensive Scripting** | `set -euo pipefail`, I/O redirection (`stdin`/`stdout`/`stderr`), guard clauses, traps | Resilient, non-interactive CI/CD deployment scripts that fail safely and transparently. |
| **Security & Identity (IAM)** | UIDs, GIDs, `/etc/passwd`, `/etc/shadow`, `visudo`, Principle of Least Privilege | Multi-tenant user isolation, non-root container runtimes, audit trail compliance. |
| **Access Control (DAC)** | Octal/Symbolic modes, Directory `x` bits, `umask`, SUID, SGID (`2775`), Sticky Bit | Collaborative shared team workspaces and permission-restricted secrets management. |
| **Incident Response & SRE** | Log forensic triage (`/var/log/auth.log`), stream parsing (`awk`, `sed`, `grep`), Root Cause Analysis | Fast MTTR (Mean Time to Resolution) during production system outages. |

---

## 📊 Month 1: Linux & Bash Foundations (Days 1–21)

Every lab directory is standardized to contain:
- **`notes.md`**: Comprehensive architectural theory, command tables, and a **real-world Incident & Troubleshooting Journal (Post-Mortem)**.
- **Working Scripts (`.sh`)**: Tested, idempotent, production-ready Bash automation utilities.

| Day | System Core (Linux Fundamentals) | Automation Companion (Bash Scripting) | Working Deliverable | Incident Post-Mortem |
|:---:|---|---|---|---|
| **[Day 01](month-01-linux-and-bash/day-01-first-contact-and-scripting/)** | Ubuntu Server 24.04 VM Setup, Terminal vs. Shell | Script execution mechanics, shebang, comments | [`hello.sh`](month-01-linux-and-bash/day-01-first-contact-and-scripting/hello.sh) | SSH network timeout & NAT port forwarding |
| **[Day 02](month-01-linux-and-bash/day-02-filesystem-and-shebang/)** | Inode navigation, relative/absolute paths, `ls -l` | Execution bits (`chmod +x`), the security model of `./` | [`shebang_demo.sh`](month-01-linux-and-bash/day-02-filesystem-and-shebang/shebang_demo.sh) | `./` execution denied & umask defaults |
| **[Day 03](month-01-linux-and-bash/day-03-crud-operations-and-variables/)** | Inode unlinking, `rm` permanent dangers, wildcards | Variable assignment, single vs. double quoting rules | [`create_folder.sh`](month-01-linux-and-bash/day-03-crud-operations-and-variables/create_folder.sh) | Wildcard expansion & accidental deletion |
| **[Day 04](month-01-linux-and-bash/day-04-file-reading-and-command-substitution/)** | Stream viewers (`less`, `head`, `tail -f`), Vim survival | Command substitution `$(date)` & dynamic timestamps | [`timestamp_backup.sh`](month-01-linux-and-bash/day-04-file-reading-and-command-substitution/timestamp_backup.sh) | Terminal freeze via raw binary streaming |
| **[Day 05](month-01-linux-and-bash/day-05-offline-help-and-user-input/)** | Manual sections (1, 5, 8), `apropos`, offline discovery | User prompts (`read -p`) & dynamic input validation | [`interactive_mkdir.sh`](month-01-linux-and-bash/day-05-offline-help-and-user-input/interactive_mkdir.sh) | Missing man pages in cloud minimal AMIs |
| **[Day 06](month-01-linux-and-bash/day-06-filesystem-hierarchy-and-arguments/)** | FHS standard (`/etc`, `/var`, `/tmp`, `/usr/bin` vs `/sbin`) | CLI arguments (`$0`, `$1`, `$#`, `$@`) | [`args_demo.sh`](month-01-linux-and-bash/day-06-filesystem-hierarchy-and-arguments/args_demo.sh) | Data loss via volatile `/tmp` reboot wipe |
| **[Day 07](month-01-linux-and-bash/day-07-finding-files-and-exit-codes/)** | Deep file search (`find -exec`), disk utilization | Exit codes (`$?`), `exit 1`, pipeline gating in CI/CD | [`check_exit_status.sh`](month-01-linux-and-bash/day-07-finding-files-and-exit-codes/check_exit_status.sh) | Masked pipeline errors & `set -o pipefail` |
| **[Day 08](month-01-linux-and-bash/day-08-grep-searching-and-if-statements/)** | Pattern searching (`grep -rni`), regular expressions | Conditional logic (`if/else`), defensive guard clauses | [`check_file_exists.sh`](month-01-linux-and-bash/day-08-grep-searching-and-if-statements/check_file_exists.sh) | Premature script crash via grep under `set -e` |
| **[Day 09](month-01-linux-and-bash/day-09-pipes-redirection-and-test-conditions/)** | File descriptors (`0`, `1`, `2`), pipes (`\|`), `tee` | File test flags (`-f`, `-d`, `-r`, `-s`) & string tests | [`test_conditions.sh`](month-01-linux-and-bash/day-09-pipes-redirection-and-test-conditions/test_conditions.sh) | Headless cron job hung waiting on stdin |
| **[Day 10](month-01-linux-and-bash/day-10-text-processing-and-arithmetic/)** | Text transformation (`sort`, `uniq`, `cut`, `awk`, `sed`) | Arithmetic expansion `$(( ))` & integer comparisons | [`file_count_alert.sh`](month-01-linux-and-bash/day-10-text-processing-and-arithmetic/file_count_alert.sh) | Uniq metric inaccuracy on unsorted streams |
| **[Day 11](month-01-linux-and-bash/day-11-users-groups-and-for-loops/)** | Multi-user security, `/etc/passwd`, `/etc/shadow`, `su -` | The `for` loop over lists, number ranges, and file globs | [`batch_rename.sh`](month-01-linux-and-bash/day-11-users-groups-and-for-loops/batch_rename.sh) | Environment variable corruption in `su` |
| **[Day 12](month-01-linux-and-bash/day-12-permissions-matrix-and-loop-audits/)** | Permissions matrix (`rwx`), directory execute `x` bit | Loop-based permission auditing & bulk hardening | [`audit_permissions.sh`](month-01-linux-and-bash/day-12-permissions-matrix-and-loop-audits/audit_permissions.sh) | Directory traversal lockout with `chmod 644` |
| **[Day 13](month-01-linux-and-bash/day-13-ownership-umask-and-while-loops/)** | `chown`, `umask` calculations, SUID, SGID, Sticky bit | The `while` loop & safe line-by-line file reading | [`read_lines_safely.sh`](month-01-linux-and-bash/day-13-ownership-umask-and-while-loops/read_lines_safely.sh) | Collaboration deadlock & SetGID resolution |
| **[Day 14](month-01-linux-and-bash/day-14-sudo-privileges-and-case-menus/)** | Sudoers administration, `visudo`, `/var/log/auth.log` | Structural branching with `case`, CLI menu dispatchers | [`service_dispatcher.sh`](month-01-linux-and-bash/day-14-sudo-privileges-and-case-menus/service_dispatcher.sh) | Sudoers syntax error averted via `visudo` |
| **[Day 15](month-01-linux-and-bash/day-15-ssh-remote-access-and-output-redirection/)** | OpenSSH daemon, asymmetric keys (Ed25519), `StrictModes` | Output redirection (`>`, `>>`, `2>`, `2>&1`), structured logging | [`production_logger.sh`](month-01-linux-and-bash/day-15-ssh-remote-access-and-output-redirection/production_logger.sh) | Silent SSH auth failure via `StrictModes` |
| **[Day 16](month-01-linux-and-bash/day-16-process-monitoring-and-management/)** | Process tree (PID 1), states (`R`, `S`, `D`, `Z`), signals | Process supervision, `pgrep`, `.pid` file lock, watchdog | [`process_watchdog.sh`](month-01-linux-and-bash/day-16-process-monitoring-and-management/process_watchdog.sh) | Kernel PID exhaustion via zombie leakage |
| **[Day 17](month-01-linux-and-bash/day-17-jobs-background-and-parallel-execution/)** | Job control (`&`, `Ctrl+Z`, `jobs`, `bg`, `fg`), `nohup`, `tmux` sessions | Async execution (`&`), `$!`, process sync with `wait`, parallel workers | [`parallel_batch_processor.sh`](month-01-linux-and-bash/day-17-jobs-background-and-parallel-execution/parallel_batch_processor.sh) | SIGHUP pipeline termination on SSH disconnect & uncommitted DB state |
| **[Day 18](month-01-linux-and-bash/day-18-systemd-services-and-automation/)** | Systemd architecture (PID 1), unit hierarchy, `systemctl` lifecycle, chaos config failure | Service health status checking inside `if`, idempotent self-healing restart, single-line reporting | [`service_sentinel.sh`](month-01-linux-and-bash/day-18-systemd-services-and-automation/service_sentinel.sh) | Systemd restart thrashing & `start-limit-hit` gateway lockout |
| **[Day 19](month-01-linux-and-bash/day-19-logs-troubleshooting-and-log-checks/)** | `systemd-journald` binary logs, `journalctl` time/priority/unit filtering, `logrotate` internals | Stream parsing with `grep -c`, match counting, warning/critical alert threshold triggers | [`log_alert_sentinel.sh`](month-01-linux-and-bash/day-19-logs-troubleshooting-and-log-checks/log_alert_sentinel.sh) | Unrotated access logs exhaust 100% disk & freeze database transactions |
| **[Day 20](month-01-linux-and-bash/day-20-package-management-and-package-checks/)** | Debian packaging (`.deb`), `dpkg` vs `apt`, `update` vs `upgrade`, `remove` vs `purge`, `/etc/apt/sources.list` | Idempotent package provisioning loop, `dpkg-query` status audits, non-interactive execution | [`idempotent_package_installer.sh`](month-01-linux-and-bash/day-20-package-management-and-package-checks/idempotent_package_installer.sh) | Blind `apt-get upgrade` in cloud-init breaks PostgreSQL driver ABI |
| **[Day 21](month-01-linux-and-bash/day-21-disks-filesystems-and-storage-automation/)** | Filesystem stack (VFS, ext4/XFS, inodes), block devices (`lsblk`), `df`/`du` capacity forensics, `/etc/fstab` persistence | Disk usage percentage extraction, threshold breach sentinels (WARN/CRIT), top-5 directory hogs analysis | [`disk_space_sentinel.sh`](month-01-linux-and-bash/day-21-disks-filesystems-and-storage-automation/disk_space_sentinel.sh) & [`storage_triage_analyzer.sh`](month-01-linux-and-bash/day-21-disks-filesystems-and-storage-automation/storage_triage_analyzer.sh) | Unlinked open file descriptor leakage causes 100% disk deadlock (`df` vs `du` discrepancy) |

---

## ⚡ Quick Start & Local Validation

```bash
# 1. Clone the repository
git clone https://github.com/muhammadsaad9316/DevOps.git
cd DevOps

# 2. Grant execution permissions across working scripts
find month-01-linux-and-bash/ -type f -name "*.sh" -exec chmod +x {} +

# 3. Test a production service dispatcher script (Day 14)
./month-01-linux-and-bash/day-14-sudo-privileges-and-case-menus/service_dispatcher.sh status

# 4. Run an automated permission audit on your local directory (Day 12)
./month-01-linux-and-bash/day-12-permissions-matrix-and-loop-audits/audit_permissions.sh .

# 5. Execute production output logger with dual streams (Day 15)
./month-01-linux-and-bash/day-15-ssh-remote-access-and-output-redirection/production_logger.sh

# 6. Run process watchdog on a target service (Day 16)
./month-01-linux-and-bash/day-16-process-monitoring-and-management/process_watchdog.sh sshd

# 7. Run parallel batch processor with fan-out / fan-in worker synchronization (Day 17)
./month-01-linux-and-bash/day-17-jobs-background-and-parallel-execution/parallel_batch_processor.sh

# 8. Run systemd service health sentinel and auto-restart check (Day 18)
./month-01-linux-and-bash/day-18-systemd-services-and-automation/service_sentinel.sh --check nginx

# 9. Scan and alert on log patterns exceeding thresholds (Day 19)
./month-01-linux-and-bash/day-19-logs-troubleshooting-and-log-checks/log_alert_sentinel.sh --warn 5 --crit 10 /var/log/syslog "error"

# 10. Audit and idempotently provision system packages (Day 20)
./month-01-linux-and-bash/day-20-package-management-and-package-checks/idempotent_package_installer.sh --dry-run --install

# 11. Run storage sentinel & triage largest directories (Day 21)
./month-01-linux-and-bash/day-21-disks-filesystems-and-storage-automation/disk_space_sentinel.sh --warn 80 --crit 90
./month-01-linux-and-bash/day-21-disks-filesystems-and-storage-automation/storage_triage_analyzer.sh biggest .
```

---

## 👨‍💻 Author

**Muhammad Saad**  
*Aspiring Cloud & DevOps Engineer | Linux Systems & Infrastructure Automation*

- **GitHub**: [@muhammadsaad9316](https://github.com/muhammadsaad9316)
- **Repository**: [github.com/muhammadsaad9316/DevOps](https://github.com/muhammadsaad9316/DevOps)

---
<div align="center">
  <sub>Maintained with rigorous engineering discipline. Built as part of a 9-month continuous DevOps mastery curriculum.</sub>
</div>
