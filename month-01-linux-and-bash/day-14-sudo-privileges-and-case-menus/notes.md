# Privilege Escalation & Least Privilege Reference

## 🛡️ The Principle of Least Privilege

> **Definition**: A security architecture model stating that every module, process, or user must be granted only the minimum levels of access strictly necessary to complete their assigned function, and for the minimum duration required.

### Why Running as Permanent `root` is Dangerous:
1. **Zero Blast Radius Isolation**: A simple typo like `rm -rf / tmp/cache` (accidental space) destroys the entire operating system instantly.
2. **Loss of Accountability**: If everyone logs in directly as `root`, system audit logs cannot differentiate between who made what changes.
3. **Lateral Compromise**: A compromised service or user shell running as `root` grants attackers instant total control over memory, network sockets, and all local files.

---

## 🔒 Why You Must ALWAYS Use `visudo`
Never edit `/etc/sudoers` directly with `nano` or `vim`. 

### The `visudo` Protection Layer:
1. Locks the `/etc/sudoers` file against concurrent edits.
2. Creates a temporary copy for editing.
3. **Performs strict syntax checking before writing**: If there is a typo or missing syntax, `visudo` alerts you and refuses to commit the broken file to disk.
4. Editing `/etc/sudoers` directly with a syntax error will permanently lock **all users** out of `sudo` capabilities.

---

## 📜 Auditing `sudo` Events in `/var/log/auth.log`
Whenever a user executes `sudo`, the operating system writes an audit log:
```bash
sudo grep "COMMAND=" /var/log/auth.log | tail -n 5
```
Example log entry:
```text
Sep 18 01:40:02 ubuntu sudo:   ubuntu : TTY=pts/0 ; PWD=/home/ubuntu ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow
```
The log records:
- **Timestamp**
- **Calling User** (`ubuntu`)
- **Working Directory** (`PWD=/home/ubuntu`)
- **Target User Executed As** (`USER=root`)
- **Exact Binary Executed** (`COMMAND=/usr/bin/cat /etc/shadow`)


---

# Day 14 Hands-On Drill: Granting & Revoking Sudo Privileges

## Step 1: Create Test User
```bash
sudo useradd -m -s /bin/bash testuser
sudo passwd testuser
```

---

## Step 2: Verify Initial Unprivileged State
Switch to `testuser` and attempt an administrative action:
```bash
su - testuser
sudo ls /root
# Expected output: "testuser is not in the sudoers file. This incident will be reported."
exit
```

---

## Step 3: Grant Sudo Privileges via Group Membership
In Ubuntu/Debian systems, any member of the `sudo` group inherits root delegation rights defined in `/etc/sudoers`:
```bash
# Add testuser to supplementary group 'sudo' (-aG)
sudo usermod -aG sudo testuser

# Verify membership
groups testuser
```

---

## Step 4: Verify Sudo Execution
```bash
su - testuser
sudo ls /root
# Sudo prompts for testuser's password and succeeds!
exit
```

---

## Step 5: Revoke Sudo Privileges & Clean Up
```bash
# Remove testuser from sudo group
sudo gpasswd -d testuser sudo

# Verify revocation
groups testuser

# Delete test account and home directory
sudo userdel -r testuser
```
