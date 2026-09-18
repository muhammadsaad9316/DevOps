# Linux Filesystem Hierarchy Standard (FHS) Reference

```text
/ (Root Directory)
├── bin -> usr/bin          (Essential user command binaries)
├── sbin -> usr/sbin        (Essential system administration binaries)
├── boot/                   (Static files of the boot loader, kernel images)
├── dev/                    (Device nodes representing hardware & virtual devices)
├── etc/                    (Host-specific system-wide configuration files)
├── home/                   (User personal directories: /home/alice, /home/bob)
├── root/                   (Home directory for the root superuser)
├── lib -> usr/lib          (Essential shared libraries and kernel modules)
├── media/                  (Mount point for removable media)
├── mnt/                    (Mount point for temporarily mounted filesystems)
├── opt/                    (Add-on application software packages)
├── proc/                   (Virtual filesystem providing process and kernel info)
├── run/                    (Run-time variable data since last boot)
├── srv/                    (Data for services provided by this system)
├── sys/                    (Virtual filesystem exposing kernel subsystem parameters)
├── tmp/                    (Temporary files, often mounted as tmpfs in RAM)
├── usr/                    (Secondary hierarchy for read-only user data & utilities)
└── var/                    (Variable data files: logs, spools, caches, databases)
```

---

## 🧐 Critical Architectural Distinctions

### 1. Why does `/root` exist separately from `/home`?
In standard enterprise architectures, `/home` may reside on a separate physical disk, partition, or network mount (NFS). If `/home` fails to mount or is corrupted during boot, the root administrator still needs an accessible home directory located directly on the primary root (`/`) partition to run emergency maintenance tools.

### 2. `/usr/bin` vs `/usr/sbin`
- **`/usr/bin`**: General utilities executable by standard, unprivileged users (`curl`, `python3`, `tar`, `nano`).
- **`/usr/sbin`**: System binaries (`s` = superuser) intended for system administrators and daemons (`fdisk`, `iptables`, `sshd`, `useradd`).

### 3. Key Config Files in `/etc`:
- `/etc/hosts`: Static local hostname-to-IP lookup table.
- `/etc/resolv.conf`: DNS nameserver configuration.
- `/etc/os-release`: OS distribution identification data.
- `/etc/fstab`: Filesystem mount definitions at boot.


---

# The `/tmp` Persistence & Reboot Test

## Objective
Verify whether files created in `/tmp` survive a reboot or are volatile.

---

## Lab Steps
1. Create a sentinel test file inside `/tmp`:
   ```bash
   echo "Testing volatility at $(date)" > /tmp/sentinel_test.txt
   cat /tmp/sentinel_test.txt
   ```
2. Reboot the virtual machine:
   ```bash
   sudo reboot
   ```
3. Reconnect and check if `/tmp/sentinel_test.txt` still exists:
   ```bash
   ls -l /tmp/sentinel_test.txt
   ```

---

## Conclusion & System Behavior
In modern systemd-based Linux distributions (like Ubuntu 24.04), `/tmp` is mounted as a virtual memory filesystem (`tmpfs`) or cleaned on boot by `systemd-tmpfiles-setup.service`. Files stored in `/tmp` are wiped upon system reboot. **Never store persistent data in `/tmp`.**
