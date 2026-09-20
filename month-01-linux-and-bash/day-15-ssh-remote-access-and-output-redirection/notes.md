# Day 15: SSH Remote Access & Production Output Redirection

## 🌐 OpenSSH Architecture & Cryptographic Foundations

Secure Shell (SSH) is the industry-standard cryptographic protocol for operating network services securely over an unsecured network. It replaced legacy plaintext protocols such as Telnet, `rlogin`, and FTP.

### Asymmetric Cryptography & Key Mechanics
SSH public-key authentication relies on asymmetric cryptography:
- **Private Key (`id_ed25519`)**: Kept strictly secret on the client machine. Never transmitted across the network, shared, or checked into version control. It signs authentication challenges sent by the server.
- **Public Key (`id_ed25519.pub`)**: Copied to target servers and placed into `~/.ssh/authorized_keys`. The server uses it to encrypt verification challenges that only the matching private key can solve.

```text
[ Client Workstation ]                               [ Remote Ubuntu Server ]
  Private Key (~/.ssh/id_ed25519)                      Public Key (~/.ssh/authorized_keys)
         │                                                            │
         │ (1) Initiate SSH Connection (Port 22)                      │
         ├───────────────────────────────────────────────────────────>│
         │                                                            │
         │ (2) Server sends encrypted challenge nonce                 │
         │<───────────────────────────────────────────────────────────┤
         │                                                            │
         │ (3) Client signs challenge with Private Key                │
         ├───────────────────────────────────────────────────────────>│
         │                                                            │
         │ (4) Server verifies signature using Public Key             │
         │<─── Authentication Successful ─── Session Opened ──────────┤
```

### Modern Key Algorithms: Ed25519 vs. RSA
- **Ed25519 (Recommended)**: Elliptic-curve cryptography based on Curve25519. Fast, compact (68-character public key), constant-time signature generation (immune to cache-timing side-channel attacks), and equivalent to ~3000-bit RSA security.
- **RSA (Legacy / High Compatibility)**: Requires a minimum of `4096` bits today (`ssh-keygen -t rsa -b 4096`). Slower and larger than Ed25519.

```bash
# Generate modern, production-recommended Ed25519 keypair
ssh-keygen -t ed25519 -C "saad@devops-workstation" -f ~/.ssh/id_ed25519
```

---

## 🔒 Strict Filesystem Permissions Matrix

The OpenSSH daemon (`sshd`) enforces a security feature called **`StrictModes`**. If permissions on the `.ssh` directory, authorized keys, or the user's home directory are too permissive (e.g., writable by group or others), `sshd` **silently ignores public-key authentication** and falls back to password authentication (or outright denies access).

| Path | Recommended Octal | Symbolic Mode | Reason |
|---|:---:|:---:|---|
| `~` (Home Directory) | `750` or `755` | `drwxr-x---` | If world-writable (`777`), other users could replace `.ssh`. |
| `~/.ssh` (SSH Config Dir) | `700` | `drwx------` | Only owner can read, write, and traverse. |
| `~/.ssh/id_ed25519` (Private Key) | `600` | `-rw-------` | Strictly owner read/write. SSH client refuses keys with loose permissions. |
| `~/.ssh/id_ed25519.pub` (Public Key) | `644` | `-rw-r--r--` | Readable by anyone, writable only by owner. |
| `~/.ssh/authorized_keys` | `600` | `-rw-------` | Only owner can add/modify authorized identities. |
| `~/.ssh/config` (Client Config) | `600` | `-rw-------` | Protects host mappings, aliases, and identity directives. |

```bash
# Apply standard permissions hardening
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys ~/.ssh/id_* 2>/dev/null || true
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

---

## 🛡️ Hardening `/etc/ssh/sshd_config`

In enterprise infrastructure, password-based SSH authentication is disabled to eliminate brute-force attack vectors.

### Core Hardening Directives (`/etc/ssh/sshd_config` or `/etc/ssh/sshd_config.d/99-hardened.conf`):
```text
# Disable password authentication completely
PasswordAuthentication no

# Prohibit root from logging in directly (must log in as unprivileged user and use sudo)
PermitRootLogin no

# Enforce public key authentication
PubkeyAuthentication yes

# Reject empty passwords
PermitEmptyPasswords no

# Enforce strict ownership and permissions checking
StrictModes yes

# Limit authentication attempts before disconnection
MaxAuthTries 3

# Terminate idle sessions after 10 minutes (300s x 2)
ClientAliveInterval 300
ClientAliveCountMax 2
```

### Safety Protocol Before Restarting SSHD
> [!CAUTION]
> Never restart `sshd` without first testing configuration syntax. A broken configuration can lock you out of remote systems permanently.

```bash
# 1. Validate configuration syntax
sudo sshd -t

# 2. If no errors are returned, reload or restart the service
sudo systemctl reload ssh

# 3. CRITICAL: Keep your current terminal session OPEN.
# Open a second terminal window to test logging in with your key before disconnecting!
```

---

## ⚡ Streamlining Access via `~/.ssh/config`

Instead of typing lengthy commands like `ssh -i ~/.ssh/id_ed25519 -p 22 ubuntu@192.168.1.150`, configure host aliases in `~/.ssh/config`:

```text
Host devvm
    HostName 192.168.1.150
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Now, remote access is a single clean command:
```bash
ssh devvm
```

---

## 📤 Output & Redirection Mechanics in Shell Scripts

Every Linux process starts with three default POSIX file descriptors:
- **`0` (`stdin`)**: Standard Input (keyboard/stream input)
- **`1` (`stdout`)**: Standard Output (normal program messages)
- **`2` (`stderr`)**: Standard Error (diagnostic and failure messages)

### Redirection Operators Table
| Syntax | Target | Description |
|---|---|---|
| `command > file` | `stdout` | Overwrites `file` with standard output. |
| `command >> file` | `stdout` | Appends standard output to `file`. |
| `command 2> error.log` | `stderr` | Overwrites `error.log` with error output. |
| `command 2>> error.log` | `stderr` | Appends error output to `error.log`. |
| `command > out.log 2> err.log` | `stdout` + `stderr` | Separates standard output and errors into distinct files. |
| `command &> combined.log` | All streams | Merges both `stdout` and `stderr` into one log file. |
| `command 2>&1` | Stream merge | Redirects `stderr` (2) into the same destination as `stdout` (1). |
| `command \| tee -a app.log` | Stream split | Writes to `stdout` (screen) AND appends to `app.log` simultaneously. |

---

# Day 15 Hands-On Drill: OpenSSH Setup & Key Provisioning

### Step 1: Install & Verify OpenSSH Server
```bash
sudo apt update && sudo apt install -y openssh-server
sudo systemctl enable --now ssh
sudo systemctl status ssh
```

### Step 2: Generate Ed25519 Key Pair on Client
```bash
ssh-keygen -t ed25519 -C "lab-operator" -f ~/.ssh/id_ed25519
```

### Step 3: Transfer Public Key to Remote Server
```bash
# Using ssh-copy-id (standard utility)
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@<VM_IP_ADDRESS>

# Alternative manual method:
cat ~/.ssh/id_ed25519.pub | ssh ubuntu@<VM_IP_ADDRESS> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### Step 4: Validate Passwordless Key Authentication
```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@<VM_IP_ADDRESS> "uptime"
```

### Step 5: Harden SSH Configuration
```bash
sudo sed -i -E 's/^#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i -E 's/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sshd -t && sudo systemctl reload ssh
```

---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Silent Public-Key Authentication Rejection via `StrictModes`
- **Symptom / Alert**: An engineer added their public key to `~/.ssh/authorized_keys` on a staging server. When executing `ssh -i ~/.ssh/id_ed25519 deploy@stage01`, the server repeatedly prompted for a password instead of using the key.
- **Investigation & Triage**:
  - Ran SSH client in verbose mode:
    ```bash
    ssh -vvv -i ~/.ssh/id_ed25519 deploy@stage01
    ```
    Output showed key offered, but server replied: `debug1: Authentications that can continue: publickey,password` and skipped the key without descriptive client-side errors.
  - Checked server-side authentication logs:
    ```bash
    sudo tail -n 25 /var/log/auth.log
    ```
    Discovered error:
    ```text
    sshd[18492]: Authentication refused: bad ownership or modes for directory /home/deploy
    ```
- **Root Cause Analysis (RCA)**: Another admin had previously run `chmod 777 /home/deploy` to "fix a file sharing permission issue". OpenSSH's `StrictModes` rejected public key authentication because a world-writable home directory allows non-privileged local users to replace or modify `.ssh/authorized_keys`.
- **Remediation & Fix**:
  - Restored proper permissions on the home directory and `.ssh` folder:
    ```bash
    chmod 750 /home/deploy
    chmod 700 /home/deploy/.ssh
    chmod 600 /home/deploy/.ssh/authorized_keys
    ```
  - Re-attempted SSH connection; authentication immediately succeeded without password prompt.
- **Engineering Takeaway**: OpenSSH treats file permissions as a fundamental security boundary. Never assign `777` permissions to home directories or SSH assets. When public key auth fails silently, always inspect server-side `/var/log/auth.log`.
