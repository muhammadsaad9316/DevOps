# Day 21: Disks, Filesystems, Storage Hierarchy & Capacity Automation

## 🧠 The Linux Storage Stack: From Silicon to Mount Point

In enterprise Linux environments, storage is organized into a modular, multi-tier abstraction hierarchy. Understanding each layer is essential for capacity planning, high-performance I/O tuning, and forensic triage:

```text
 ┌────────────────────────────────────────────────────────┐
 │            User Applications & System Daemons          │
 │       (Read/Write operations: open(), read(), write()) │
 └───────────────────────────┬────────────────────────────┘
                             │ System Calls
                             ▼
 ┌────────────────────────────────────────────────────────┐
 │           VFS (Virtual Filesystem Switch)              │
 │   Kernel abstraction layer providing a uniform POSIX   │
 │   API regardless of underlying filesystem format.      │
 └───────────────────────────┬────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
    ┌─────────┐         ┌─────────┐         ┌─────────┐
    │  ext4   │         │   XFS   │         │  Btrfs  │  (Filesystem Drivers)
    └────┬────┘         └────┬────┘         └────┬────┘
         └───────────────────┼───────────────────┘
                             │ Block I/O Layer (bio)
                             ▼
 ┌────────────────────────────────────────────────────────┐
 │         Block Device Layer & I/O Schedulers            │
 │     (/dev/mapper, LVM Logical Volumes, Software RAID)   │
 └───────────────────────────┬────────────────────────────┘
                             │ SCSI / NVMe / VirtIO Drivers
                             ▼
 ┌────────────────────────────────────────────────────────┐
 │            Physical / Virtual Block Devices            │
 │   • /dev/nvme0n1  (High-speed NVMe SSD)                │
 │   • /dev/sda      (SATA / SAS Disk or AWS EBS Volume)  │
 │   • /dev/vda      (KVM / QEMU VirtIO Virtual Disk)     │
 └────────────────────────────────────────────────────────┘
```

---

## 🔍 Block Devices & Identification: `lsblk` & `blkid`

Before a filesystem can be mounted, the operating system must detect and partition block devices.

### Block Device Naming Conventions
- `/dev/sd[a-z]`: SCSI, SATA, USB drives, and AWS EBS volumes attached via Xen or VirtIO-SCSI emulation.
- `/dev/nvme[0-9]n[1-9]`: Non-Volatile Memory Express drives (modern bare-metal NVMe and AWS Nitro instances like `c5`, `m5`, `t4g`).
- `/dev/vd[a-z]`: VirtIO paravirtualized disks used inside KVM and OpenStack virtual machines.
- `/dev/loop[0-9]`: Virtual loopback devices representing file-backed disks (commonly used by Snap packages and Docker).

### Major and Minor Numbers
Every block device registered in `/dev` has two identifying integers:
- **Major Number**: Identifies the device driver responsible for handling the hardware (e.g., `8` for SCSI/SATA disk driver `sd`).
- **Minor Number**: Identifies the specific physical device or partition instance managed by that driver (e.g., `8:0` for `/dev/sda`, `8:1` for `/dev/sda1`).

```bash
# View block devices with tree topology, filesystem types, mount points, and UUIDs
lsblk -o NAME,MAJ:MIN,RM,SIZE,RO,TYPE,FSTYPE,MOUNTPOINT,UUID
```

### The Universally Unique Identifier (`UUID`)
Device node names like `/dev/sdb1` are assigned dynamically by the Linux kernel as hardware is discovered at boot. If storage cabling changes or cloud disk attachments shift, `/dev/sdb` can become `/dev/sdc`.

To prevent mount corruption, filesystems are tagged with a permanent **`UUID`** at format time. You query this with `blkid`:
```bash
sudo blkid
# Output:
# /dev/sda1: UUID="b49463c7-872f-48d6-946e-1d54e48816cb" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="c4b9d031-01"
```

---

## 📊 Disk Capacity Forensics: `df` vs `du`

A fundamental distinction in Linux system administration is understanding how `df` and `du` calculate space:

| Metric / Tool | `df` (Disk Free) | `du` (Disk Usage) |
|---|---|---|
| **Mechanism** | Calls the kernel `statvfs()` system call directly on the mounted filesystem superblock metadata. | Recursively walks the directory tree with `lstat()` / `fstatat()` and sums allocated 4KB blocks for visible files. |
| **Speed** | Instant ($O(1)$ constant time), regardless of disk size or number of files. | Slower ($O(N)$ linear time), proportional to directory depth and file count. |
| **Deleted Open Files** | **Includes** space held by deleted files whose file descriptors are still open by running processes. | **Excludes** deleted files because they no longer have directory entries. |
| **Scope** | Filesystem / mount point boundary. | Target directory path and its recursive subtrees. |

### Reading Every Column of `df -h`
```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        40G   18G   20G  48% /
```

1. **`Filesystem`**: The block device, virtual device, or network remote source holding the filesystem (`/dev/sda1`, `tmpfs`, `nfs-server:/share`).
2. **`Size`**: The total addressable volume size formatted into filesystem blocks.
3. **`Used`**: The total space occupied by existing files, directories, filesystem journals, and metadata tables.
4. **`Avail`**: The space immediately available for allocation by unprivileged user processes.
5. **`Use%`**: Percentage calculated as: $\frac{\text{Used}}{\text{Used} + \text{Avail}} \times 100\%$.
6. **`Mounted on`**: The directory path in the virtual filesystem hierarchy where this storage tree is attached.

> 💡 **The Reserved 5% Mystery**: Why doesn't $\text{Used} + \text{Avail} = \text{Size}$? By default, `mkfs.ext4` reserves **5% of total filesystem blocks** for the `root` superuser (`tune2fs -m 5`). This prevents unprivileged user processes from completely freezing the operating system and prevents filesystem fragmentation. On a 1 TB data volume, 5% is 50 GB of wasted space! You can reduce this reserve to 1% or 0% using:
> ```bash
> sudo tune2fs -m 1 /dev/sdb1
> ```

---

## 🧬 Inodes vs Data Blocks: Inode Exhaustion (`df -i`)

Filesystems like `ext4` divide disk storage into two distinct components:
1. **Data Blocks**: Chunks of storage (usually 4 KB) containing the actual byte contents of your files.
2. **Inodes (Index Nodes)**: Data structures containing file metadata (owner, permissions, size, timestamps, block pointers). Every file and directory on disk requires exactly **one** inode.

```text
┌────────────────────────────────────────────────────────┐
│                    EXT4 FILESYSTEM                     │
├────────────────────────────┬───────────────────────────┤
│        Inode Table         │        Data Blocks        │
│  [Inode 1] [Inode 2] ...   │ [Block 1] [Block 2] ...   │
│  (Stores file metadata)    │ (Stores file payloads)    │
└────────────────────────────┴───────────────────────────┘
```

### The Inode Exhaustion Outage (`No space left on device`)
When formatting an ext4 filesystem, a fixed number of inodes is permanently allocated based on disk capacity.
- If an application generates millions of empty or 1-byte files (such as micro-cache files or unrotated session cookies), **all inodes can be consumed while 95% of disk space remains free!**
- The system will throw `error: ENOSPC (No space left on device)` even though `df -h` shows plenty of gigabytes available!

```bash
# Check inode saturation across filesystems
df -i
# Output:
# Filesystem      Inodes  IUsed   IFree IUse% Mounted on
# /dev/sda1      2621440 2621430     10  100% /   <-- INODE EXHAUSTION!
```

---

## 📁 Finding Space Consumers: `du` Best Practices

When disk capacity warnings fire, pinpointing the culprit directories without crashing system I/O requires defensive parameters:

```bash
# 1. Find the top 5 largest items in the current directory (human-readable)
du -xh --max-depth=1 . | sort -hr | head -n 6

# 2. Key flags breakdown:
#    -x, --one-file-system : CRITICAL! Do NOT traverse into other mounted filesystems (prevents walking /proc, /sys, or NFS)
#    -h, --human-readable  : Format sizes as K, M, G
#    --max-depth=1         : Inspect immediate child folders only (avoids millions of redundant stdout lines)
#    sort -hr              : Sort numerically in reverse order (largest first)
```

---

## 💽 Partitioning, Formatting & Mounting Lifecycle

Adding a new disk volume to a Linux server follows a 4-step sequence:

```text
 1. Attach Disk  ──► 2. Partition  ──► 3. Create Filesystem ──► 4. Mount
   (/dev/sdb)         (fdisk/parted)        (mkfs.ext4)           (mount)
```

### Step 1: Create a Partition
```bash
# Partition a raw disk using fdisk or parted
sudo fdisk /dev/sdb
# Commands inside fdisk:
# 'n' -> new partition (primary, default sector boundaries)
# 'w' -> write partition table to disk and exit
```

### Step 2: Format the Filesystem
Formatting writes the superblock, inode tables, and block allocation bitmaps:
```bash
# Format partition as ext4
sudo mkfs.ext4 -L "DATA_STORE" /dev/sdb1

# Alternatively, format as modern enterprise XFS (RHEL/CentOS default)
# sudo mkfs.xfs -L "DATA_STORE" /dev/sdb1
```

### Step 3: Mount the Filesystem
```bash
# Create target mount point directory
sudo mkdir -p /mnt/data

# Mount partition to directory
sudo mount /dev/sdb1 /mnt/data

# Verify mount
df -hT /mnt/data
```

### Step 4: Unmounting & Resolving "Target is busy"
```bash
# Normal unmount
sudo umount /mnt/data

# If umount fails with: "umount: /mnt/data: target is busy."
# Find which process or open shell is locking the mount point:
sudo fuser -mv /mnt/data
# Or:
sudo lsof +f -- /mnt/data

# Emergency lazy unmount (detaches immediately from VFS, cleans up when references close)
sudo umount -l /mnt/data
```

---

## 📜 Persistent Mount Configuration: `/etc/fstab`

Manual `mount` commands do not survive system reboots. To persist mounts across reboots, entries must be registered in `/etc/fstab`.

### The 6-Field Syntax of `/etc/fstab`
```text
UUID=3a7b8e12-0f41-4c6e-92b1-123456789abc  /mnt/data  ext4  defaults,nofail,noatime  0  2
──────────────────────────────────────────  ─────────  ────  ───────────────────────  ─  ─
                    │                            │       │              │             │  │
             1. Device / UUID              2. Mount Pt 3. Type      4. Options     5.Dump 6.Fsck
```

| Field | Meaning | Production Best Practice |
|---|---|---|
| **1. Device Spec** | Block device (`UUID=...`, `LABEL=...`, or `/dev/sdb1`). | **Always use `UUID`**. Device names like `/dev/sdb1` can re-enumerate randomly after reboots. |
| **2. Mount Point** | Absolute directory path where storage attaches. | Ensure the target directory exists (`mkdir -p`). |
| **3. Filesystem Type**| `ext4`, `xfs`, `btrfs`, `nfs`, `cifs`, etc. | Must match the filesystem created by `mkfs`. |
| **4. Mount Options** | Comma-separated flags controlling behavior. | `defaults,nofail,noatime`. |
| **5. Dump Frequency**| Legacy backup utility flag (`0` or `1`). | Set to `0` (disabled on modern systems). |
| **6. Fsck Order** | Filesystem check priority at boot. | `1` for root (`/`), `2` for data disks, `0` to skip fsck. |

### ⚠️ The Critical `nofail` Flag for Cloud & Secondary Disks
If a secondary disk listed in `/etc/fstab` is detached, corrupted, or fails to initialize at boot time, systemd will stall the boot sequence and drop into **Emergency Maintenance Mode (`emergency.target`)**.
- Adding the **`nofail`** option instructs systemd to continue booting normally even if this specific volume cannot be mounted!
- Recommended options for data volumes: `defaults,nofail,noatime`.

### 🛡️ Testing `/etc/fstab` Before Rebooting
Never reboot a server without testing your `/etc/fstab` changes! A single syntax typo can prevent remote SSH recovery:
```bash
# Test all non-mounted fstab entries without rebooting
sudo mount -a

# If mount -a completes with exit code 0 and no output, the syntax is valid!
echo $?
```

---

## 💥 Breaking It: Disk Saturation Mechanics (`No space left on device`)

Understanding how systems fail when storage reaches 100% is critical for SREs:

### How to Allocate Test Dummy Files
```bash
# Method A: Instant sparse / metadata pre-allocation (Fastest, does not write all zeroes)
sudo fallocate -l 1G /mnt/data/test_dummy.img

# Method B: Raw zero stream allocation (Compatible with all filesystems)
sudo dd if=/dev/zero of=/mnt/data/test_dummy.img bs=1M count=1024 status=progress
```

### Cascading Failure Modes of a 100% Full Disk
1. **Database Writes Crash**: Databases (PostgreSQL, MySQL, Redis) cannot write to write-ahead logs (WAL) or append-only files (AOF) and immediately abort or switch to read-only panic mode.
2. **Systemd Services Fail to Fork**: Services trying to allocate PID locks or temporary sockets in `/var/run` or `/tmp` crash.
3. **Session Lockout**: Users cannot SSH into the system because OpenSSH cannot create terminal allocation files or update `/var/log/lastlog`.
4. **Shell History Loss**: Bash cannot write `$HISTFILE` upon logout, corrupting command audit trails.

---

## 🛠️ Hands-On Drills

### Drill 1: Deep Capacity Inspection with `df -h` and `df -i`
```bash
# 1. Inspect disk storage capacity
df -h --output=source,fstype,size,used,avail,pcent,target

# 2. Inspect inode capacity
df -i
```

### Drill 2: Pinpointing Space Hogs with `du`
```bash
# Find 5 largest folders in current directory
du -xh --max-depth=1 . | sort -hr | head -n 6
```

### Drill 3: Correlating Block Devices with Mounts
```bash
# View block topology and match partitions to mounts
lsblk -f
```

### Drill 4: Creating, Formatting & Mounting a Loopback Virtual Disk
You can practice the complete disk lifecycle on any Linux VM without needing physical hardware:
```bash
# 1. Create a 256MB file filled with zeroes
dd if=/dev/zero of=/tmp/virtual_disk.img bs=1M count=256

# 2. Format the virtual image file directly as ext4
mkfs.ext4 -F /tmp/virtual_disk.img

# 3. Create mount target directory
sudo mkdir -p /mnt/looptest

# 4. Mount the loopback image
sudo mount -o loop /tmp/virtual_disk.img /mnt/looptest

# 5. Verify mount in df
df -h /mnt/looptest

# 6. Clean up
sudo umount /mnt/looptest
rm -f /tmp/virtual_disk.img
sudo rmdir /mnt/looptest
```

### Drill 5: Safely Auditing `/etc/fstab`
```bash
# Check existing fstab entries
cat /etc/fstab

# Test-load mounts to confirm no syntax regressions
sudo mount -a
```

### Drill 6: Controlled Disk Saturation & Recovery
```bash
# Create sandbox directory
mkdir -p /tmp/disk_chaos && cd /tmp/disk_chaos

# Simulate large temporary file
dd if=/dev/zero of=huge_blob.tmp bs=1M count=100

# Inspect usage
ls -lh huge_blob.tmp

# Clean up
rm -f huge_blob.tmp
```

---

## 🚨 SRE Incident Post-Mortem

### Case Study: The "Ghost File" Outage — 100% Root Disk Exhaustion with No Files Found by `du`
- **Severity**: P1 Major Production Outage (Kubernetes Cluster Node DiskPressure Eviction).
- **Incident Summary**: At 04:15 UTC, alerts fired across production nodes indicating `/` (root partition) reached 100% capacity (`Use% 100`). Kubernetes marked the nodes with `DiskPressure` taint, evicting all application pods. Engineers logged in and ran `du -sh /*` to identify large log files, but the sum of all directories on disk was only **32 GB on an 80 GB volume**. Nearly **48 GB of storage had vanished!**
- **Triage & Forensic Investigation**:
  1. `df -h /` showed:
     `Size: 80G, Used: 76G, Avail: 0G, Use%: 100%`
  2. `du -xh --max-depth=1 /` showed:
     `Total accounted files: 32G`
  3. The discrepancy between `df` and `du` immediately indicated **unlinked deleted files held open by running processes**.
  4. SREs ran `lsof +L1` to inspect open file handles with an unlinked link count (`NLINK == 0`):
     ```bash
     sudo lsof +L1
     # Or:
     sudo lsof | grep '(deleted)' | sort -k7 -nr | head -n 10
     ```
  5. The output revealed a containerized Java microservice (`pid 18420`) holding an open descriptor to `/var/log/app/transaction.log (deleted)` with an allocated size of **46 GB**.
- **Root Cause Analysis (RCA)**:
  - An automated cron job had run `rm -f /var/log/app/transaction.log` to "clean up" space.
  - In POSIX filesystems, running `rm` simply unlinks the directory inode reference. If a running process has an open file descriptor (`open()` syscall) pointing to that inode, the Linux kernel **does not free the underlying data blocks** until the process closes the descriptor or terminates.
  - Because the Java service kept appending bytes to the unlinked file descriptor, disk space kept depleting while directory-walking tools like `du` could not see the unlinked file.
- **Remediation & Permanent Engineering Fixes**:
  1. **Immediate Zero-Downtime Space Recovery**: Truncated the open file descriptor directly through the Linux `/proc` filesystem without killing the production service:
     ```bash
     # Find file descriptor number (e.g. fd 4)
     # Truncate to zero bytes:
     sudo truncate -s 0 /proc/18420/fd/4
     # Or using shell redirection:
     sudo bash -c '> /proc/18420/fd/4'
     ```
     Disk space instantly dropped from 100% to 42%!
  2. **Logrotate Modernization**: Reconfigured log rotation to use `copytruncate` or proper `SIGHUP` signal notification instead of destructive `rm`.
  3. **Automated Monitoring Sentinel**: Deployed an automated storage sentinel script (`disk_space_sentinel.sh`) to track both filesystem block capacity and inode consumption, alerting on threshold breaches before `DiskPressure` cascades occur.
