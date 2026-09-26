# Day 21: Disks and Filesystems

## 📖 Key Concepts

Linux treats storage as a tree where physical disks or partitions are mounted to directories.

### 1. Checking Free Space: `df -h`
`df` (Disk Free) shows the total, used, and available space on all mounted filesystems.
The `-h` flag makes numbers human-readable (MB, GB).

| Column | What It Means |
|---|---|
| **Filesystem** | The disk device name (e.g. `/dev/sda1` or cloud volume). |
| **Size** | Total formatted storage capacity. |
| **Used** | Space currently occupied by files and system data. |
| **Avail** | Space left for users and applications to write new files. |
| **Use%** | Percentage of disk space currently in use. |
| **Mounted on** | The folder path where this disk is attached (e.g. `/`, `/home`, `/mnt/data`). |

### 2. Checking Inodes: `df -i`
Every file on Linux requires an **inode** (index node) to store its metadata (permissions, owner, size).
- If your system runs out of inodes, you cannot create new files even if `df -h` shows lots of free gigabytes!
- Run `df -i` to check inode usage percentage.

### 3. Finding Large Folders: `du`
`du` (Disk Usage) scans directories and calculates how much space their files consume.

```bash
# Find the 5 largest items in the current directory:
du -h --max-depth=1 . | sort -hr | head -n 6
```
- `-h`: Human-readable size (K, M, G).
- `--max-depth=1`: Looks only at direct subfolders (not every nested folder).
- `sort -hr`: Sorts numbers in reverse (largest on top).

### 4. Listing Block Devices: `lsblk`
`lsblk` lists all storage drives (block devices) attached to the system:
```bash
lsblk
```
It shows the device name (like `sda`, `sdb`), size, type (`disk` or `part`), and where it is mounted.

### 5. Mounting a New Disk
When you add a second virtual disk to a server:
```bash
# 1. Format the new disk with an ext4 filesystem:
sudo mkfs.ext4 /dev/sdb

# 2. Create a folder to mount it to:
sudo mkdir -p /mnt/data

# 3. Mount the disk to the folder:
sudo mount /dev/sdb /mnt/data

# 4. Unmount when done:
sudo umount /mnt/data
```

### 6. Making Mounts Permanent: `/etc/fstab`
Manual mounts disappear after a reboot. The `/etc/fstab` file lists disks that should mount automatically at boot time.

Example line in `/etc/fstab`:
```text
UUID=1234-abcd-5678  /mnt/data  ext4  defaults,nofail  0  2
```
- **`nofail`**: Very important in cloud environments! If the secondary disk is missing at boot, `nofail` lets the server boot normally instead of getting stuck in emergency mode.

---

## 🛠️ Hands-On Drills

### Drill 1: Check Disk and Inode Space
```bash
# Check disk usage
df -h

# Check inode usage
df -i
```

### Drill 2: Find Big Folders
```bash
# See which folders take the most space
du -h --max-depth=1 . | sort -hr | head -n 5
```

### Drill 3: Simulate a Full Disk & Clean Up
```bash
# Create a 50MB dummy file to test space allocation
fallocate -l 50M test_large_file.tmp

# Verify it was created and check size
ls -lh test_large_file.tmp

# Clean it up immediately
rm -f test_large_file.tmp
```

---

## 🚨 Incident & Troubleshooting Journal (Post-Mortem)

### Case Study: Disk is 100% Full, But `du` Shows Free Space
- **Symptom**: `df -h` shows the root disk `/` is 100% full, but `du` only finds 30 GB of files on an 80 GB disk.
- **Cause**: A log file was deleted with `rm`, but a running application still had the file open. Linux only frees disk space after the application holding the file descriptor closes it.
- **How to Find It**:
  ```bash
  sudo lsof | grep '(deleted)'
  ```
- **Fix**: Restart the application, or truncate the open file descriptor to 0 bytes:
  ```bash
  > /proc/<PID>/fd/<FD_NUMBER>
  ```
- **Lesson**: Do not use `rm` on active log files. Use `logrotate` or truncate them with `> file.log`.
