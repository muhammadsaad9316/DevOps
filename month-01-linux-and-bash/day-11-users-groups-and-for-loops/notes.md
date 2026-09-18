# Linux Users & Groups Architecture

## 🔍 Parsing `/etc/passwd`
A sample entry looks like:
```text
ubuntu:x:1000:1000:Ubuntu User,,,:/home/ubuntu:/bin/bash
```

| Field | Value in Example | Description |
|:---:|---|---|
| **1. Username** | `ubuntu` | Login account name. |
| **2. Password Placeholder** | `x` | Historically held password hash; now `x` indicates password hash is stored securely in `/etc/shadow`. |
| **3. UID (User ID)** | `1000` | Kernel numeric user identifier (`0` is always root; `<1000` are system services). |
| **4. GID (Group ID)** | `1000` | Primary group numeric identifier. |
| **5. GECOS / Comment** | `Ubuntu User,,,` | Full name, office info, contact details. |
| **6. Home Directory** | `/home/ubuntu` | User's base directory where login session starts. |
| **7. Login Shell** | `/bin/bash` | Default shell spawned when user logs in (`/usr/sbin/nologin` disables interactive shell). |

---

## 🛡️ Why `/etc/shadow` is Restricted (`640` or `000`)
`/etc/passwd` must be globally readable (`644`) so utilities like `ls` can resolve numeric UIDs into human-readable usernames. If password hashes remained in `/etc/passwd`, any unprivileged user could copy the hashes and run offline dictionary/brute-force attacks (e.g. John the Ripper or Hashcat). 

`/etc/shadow` extracts those salted password hashes and restricts read access strictly to root.


---

# `su` vs. `su -` (Login vs. Non-Login Shells)

## The Fundamental Difference

| Command | Shell Type | Working Directory | Environment (`$PATH`, `$HOME`) |
|---|---|---|---|
| `su testuser` | **Non-Login Shell** | Keeps **current working directory** of calling user. | Retains calling user's `$PATH`, `$USER`, and environment. |
| `su - testuser` *(or `su -l`)* | **Login Shell** | Switches to **target user's home directory** (`/home/testuser`). | Loads target user's clean environment (`.bash_profile`, `.profile`, `.bashrc`). |

---

## ⚠️ Why This Causes Production Outages
If you switch to root using `su root` instead of `su -`, you will NOT inherit root's admin path (`/sbin`, `/usr/sbin`). System maintenance commands (like `fdisk`, `iptables`, `systemctl`) will fail with `command not found` or execute using unprivileged paths.

**Best Practice**: Always use `su -` (with a dash) when switching accounts.


---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Build Tool Failure After Switching Accounts via `su`
- **Symptom / Alert**: Deployment engineer switched to `deployer` account via `su deployer` and attempted to run build tools, resulting in `mvn: command not found` and permission errors writing to `/home/deployer`.
- **Investigation & Triage**:
  1. Ran `pwd`: Returned `/root` (engineer was still in root's directory!).
  2. Checked environment variables: `echo $PATH` was using root's binary path, and `$HOME` was not updated.
- **Root Cause Analysis (RCA)**: `su <user>` initiates a **non-login shell**. It preserves the calling user's current directory and environment variables, failing to load `/home/deployer/.profile` or `.bashrc`.
- **Remediation & Fix**:
  - Switched using a **login shell**: `su - deployer` (with the hyphen).
  - Path and environment variables initialized correctly, and working directory shifted to `/home/deployer`.
- **Engineering Takeaway**: In production environments, always switch accounts using `su - <user>` or `sudo -i -u <user>` to ensure full environment isolation.
