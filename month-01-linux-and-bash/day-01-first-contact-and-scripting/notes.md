# Day 01 Notes: Core Linux Concepts & Command Log

## 🧠 Architectural Concepts: Terminal vs. Shell

| Component | Definition | Examples |
|---|---|---|
| **Terminal Emulator** | A graphical application that accepts keyboard input and displays text output on screen. It acts as an interface layer. | GNOME Terminal, Windows Terminal, iTerm2, Alacritty |
| **Shell** | The command-line interpreter that reads your commands, parses them, interacts with the Linux kernel, and returns output. | Bash, Zsh, Sh, Fish |
| **Console** | Historically, a physical monitor and keyboard connected directly to a mainframe; in Linux VMs, it is the direct tty interface. | `/dev/tty1` |

---

## 📖 Command Reference Log

| Command | Syntax | Description | Example Output / Notes |
|---|---|---|---|
| `whoami` | `whoami` | Displays current logged-in username. | `ubuntu` |
| `hostname` | `hostname` | Prints the system's network machine name. | `devops-lab-node` |
| `date` | `date` | Prints the current system date, time, and timezone. | `Thu Sep 18 01:25:00 UTC 2026` |
| `pwd` | `pwd` | Print Working Directory (shows full path). | `/home/ubuntu` |
| `ls` | `ls` | Lists directory contents. | `hello.sh notes.md` |
| `clear` | `clear` | Clears the terminal screen (or `Ctrl + L`). | Terminal viewport resets to top |
| `history` | `history` | Lists numbered list of executed shell commands. | Inspect recent command inputs |

---

## 💡 Practical Tip: History Expansion
- Use the **Up/Down Arrow Keys** to cycle through recent commands.
- `!!` repeats the immediate last command.
- `!n` runs command number `n` from the `history` list.
- `Ctrl + R` triggers reverse incremental search across shell history.


---

# Ubuntu Server 24.04 LTS VirtualBox Provisioning Guide

## Hardware Specifications
- **Base OS**: Ubuntu Server 24.04 LTS (Noble Numbat)
- **CPUs**: 2 vCPUs
- **RAM**: 4096 MB (4 GB)
- **Storage**: 25 GB VDI (Dynamically Allocated)
- **Network Adapter**: Bridged Adapter (or NAT with Port Forwarding for SSH on port 2222)

---

## Provisioning Checklist
1. Download official Ubuntu Server 24.04 ISO from `releases.ubuntu.com`.
2. In VirtualBox: Click **New** -> Name: `ubuntu-server-24` -> Type: `Linux` -> Version: `Ubuntu (64-bit)`.
3. Allocate Memory (4096 MB) and Processors (2 CPUs).
4. Create Virtual Hard Disk (25 GB).
5. Mount the ISO under Storage -> Controller: IDE/SATA.
6. Under Network: Set Adapter 1 to `NAT` or `Bridged Adapter`.
7. Boot VM, proceed through standard installation, and configure primary user credentials.
8. Post-install verification:
   ```bash
   uname -a
   hostnamectl
   ```


---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Host-to-Guest SSH Connection Timeout
- **Symptom / Alert**: Attempting to connect via SSH (`ssh ubuntu@10.0.2.15`) from the host OS resulted in `Connection timed out` or `Network unreachable`.
- **Investigation & Triage**:
  1. Ran `ip a` on the VM guest: IP assigned was `10.0.2.15/24`.
  2. Verified OpenSSH service status: `sudo systemctl status ssh` (service was active and listening on port 22).
  3. Checked listening sockets: `ss -tulpn | grep :22`.
- **Root Cause Analysis (RCA)**: VirtualBox's default NAT networking isolates the guest VM in a private subnet behind a virtual router. Host machines cannot route packets directly into VirtualBox private NAT IPs without port forwarding.
- **Remediation & Fix**:
  - Configured VirtualBox Network Port Forwarding rule: `Host Port 2222 -> Guest Port 22`.
  - Connected successfully via `ssh -p 2222 ubuntu@127.0.0.1`.
- **Engineering Takeaway**: Distinguish between NAT, Bridged, and Host-Only networking topologies in hypervisors before diagnosing OS-level firewall or daemon issues.
