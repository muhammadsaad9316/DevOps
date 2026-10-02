# Day 22: Archives, Remote Transfer, and Backup Automation

## 📖 Key Concepts

In Linux administration and DevOps engineering, creating archives, transferring files across servers, and automating backups are foundational tasks for disaster recovery and operational stability.

---

### 1. Tape Archive: `tar`
`tar` bundles multiple files and directories into a single uncompressed archive file (`.tar`). It preserves Linux permissions, ownership, directory structures, and timestamps.

| Flag | Meaning | Description |
|---|---|---|
| `-c` | Create | Creates a new archive. |
| `-x` | Extract | Extracts files from an archive. |
| `-t` | List / Test | Lists the contents of an archive without extracting it. |
| `-v` | Verbose | Displays the list of files being processed. |
| `-f` | File | Specifies the archive filename (must be followed immediately by the filename). |
| `-z` | Gzip | Filters the archive through `gzip` for compression (`.tar.gz`). |
| `-j` | Bzip2 | Filters through `bzip2` for higher compression (`.tar.bz2`). |
| `-C` | Change directory | Changes to the specified directory before performing operations. |

```bash
# Create an uncompressed tarball:
tar -cvf backup.tar /path/to/folder

# List contents of an archive:
tar -tvf backup.tar

# Extract archive to current folder:
tar -xvf backup.tar

# Extract archive to a specific destination:
tar -xvf backup.tar -C /opt/restore/
```

---

### 2. Compression: `gzip` & `tar.gz`
- `tar` alone does **not** compress files; it only packages them together into one container.
- `gzip` compresses a file and appends `.gz`, replacing the original file.
- Combining `tar` and `gzip` produces a `.tar.gz` (or `.tgz`) file, which is both a single container and significantly smaller in size.

```bash
# Compress a single file:
gzip database.sql            # Outputs database.sql.gz (deletes original)

# Decompress a .gz file:
gunzip database.sql.gz       # Restores database.sql

# Create a compressed tar.gz archive in one step:
tar -czvf my_backup.tar.gz /var/www/html

# Extract a compressed tar.gz archive:
tar -xzvf my_backup.tar.gz -C /var/www/html_restored
```

---

### 3. Secure Remote Copy: `scp`
`scp` uses SSH under the hood to securely copy files between machines.

```bash
# Copy file from local host machine to remote VM:
scp -P 22 ./app.tar.gz user@192.168.1.100:/home/user/backups/

# Copy file from remote VM down to local host machine:
scp user@192.168.1.100:/var/log/syslog ./remote_syslog.log

# Recursively copy an entire folder:
scp -r ./config_dir user@192.168.1.100:/tmp/
```

---

### 4. Incremental Synchronization: `rsync`
`rsync` (Remote Sync) is vastly superior to `scp` for copying directories because it uses the **remote-update delta algorithm**:
- On the first run, it copies all files.
- On subsequent runs, it inspects timestamps and sizes, copying **only the bytes that have changed**.

```bash
# Standard sync command:
rsync -avz --progress ./source_dir/ /backup/dest_dir/
```

- `-a` (Archive mode): Preserves permissions, ownership, symlinks, modification times, and recurses directories.
- `-v` (Verbose): Shows files being transferred.
- `-z` (Compress): Compresses file data during transmission across the network.
- `--delete`: Removes files in the target directory that no longer exist in the source (mirrors source exactly).
- `--dry-run`: Simulates the transfer without making any actual changes (essential safety check!).

> [!WARNING]
> **The Infamous Trailing Slash Rule:**
> - `rsync -av ./source /backup`: Creates a directory named `source` inside `/backup` (`/backup/source/...`).
> - `rsync -av ./source/ /backup`: Copies the **contents** of `source` directly into `/backup/` (`/backup/...`).
> Always test with `--dry-run` first when using `--delete`!

---

### 5. Automated Backup Retention & Rotation
Production servers quickly run out of disk space if backup files accumulate indefinitely. A robust backup policy must include automated retention pruning.

Using `find` to purge archives older than 7 days:
```bash
find /backups -maxdepth 1 -name "*_backup_*.tar.gz" -type f -mtime +7 -delete
```
- `-maxdepth 1`: Searches only inside the backup folder, preventing accidental deletion of files in subdirectories.
- `-mtime +7`: Matches files modified strictly more than 7 days (7 × 24 hours) ago.
- `-delete`: Removes the matched files safely.

---

### 6. Production Nightly Backup Blueprint
A reliable automated backup workflow consists of the following plain-English steps:

1. **Pre-flight Check**: Verify source directory exists, is readable, and verify backup destination storage has sufficient free space (`df -h`).
2. **Quiesce / Snapshot (if database)**: Dump database state to a temporary dump file (e.g. `mysqldump` or `pg_dump`).
3. **Archive & Compress**: Bundle and gzip source directories into an archive named `<service>_backup_YYYYMMDD_HHMMSS.tar.gz`.
4. **Integrity Verification**: Calculate and record the SHA-256 checksum (`sha256sum`) of the created archive to detect corruption.
5. **Offsite Replication**: Sync the archive to an offsite server or cloud storage bucket (`rsync` or S3 API).
6. **Retention Pruning**: Find and purge local and remote backup archives older than the retention threshold (e.g., 7 days).
7. **Logging & Alerting**: Record execution duration, archive size, and exit status to system logs. Send an alert if any step fails.

---

## 🛠️ Hands-On Drills

### Drill 1: Create a Tar Archive & Check Size (`d22-tar-create`)
```bash
# Create a sample project folder with dummy files
mkdir -p /tmp/project_files
echo "Configuration Data" > /tmp/project_files/config.json
echo "Application Code" > /tmp/project_files/app.js

# Create an uncompressed tar archive
tar -cvf /tmp/project.tar -C /tmp project_files

# Check file sizes
ls -lh /tmp/project.tar
du -sh /tmp/project_files
```

### Drill 2: Extract & Verify Contents Match (`d22-tar-extract`)
```bash
# Create a separate destination directory
mkdir -p /tmp/restore_test

# Extract archive into the new location
tar -xvf /tmp/project.tar -C /tmp/restore_test

# Verify contents match
diff -r /tmp/project_files /tmp/restore_test/project_files
echo "Diff exit code: $?" # 0 indicates identical files
```

### Drill 3: Compress with Gzip & Compare File Size (`d22-gzip`)
```bash
# Generate a compressible text file (~5 MB)
yes "DevOps Production Engineering Data Stream" | head -n 100000 > /tmp/sample.txt

# Record uncompressed size
ls -lh /tmp/sample.txt

# Compress with gzip
gzip /tmp/sample.txt

# Compare compressed size (.gz)
ls -lh /tmp/sample.txt.gz

# Decompress to restore
gunzip /tmp/sample.txt.gz
```

### Drill 4: Copy Files via SCP (`d22-scp`)
```bash
# Copy a local file to remote target (simulated syntax)
scp -P 22 /tmp/project.tar user@192.168.1.50:/tmp/

# Download remote file back to local machine
scp user@192.168.1.50:/tmp/project.tar /tmp/downloaded_project.tar
```

### Drill 5: Sync with Rsync & Observe Delta Transfer (`d22-rsync`)
```bash
# Create source and backup directories
mkdir -p /tmp/sync_source /tmp/sync_backup
echo "File 1" > /tmp/sync_source/file1.txt
echo "File 2" > /tmp/sync_source/file2.txt

# First sync: copies everything
rsync -av --stats /tmp/sync_source/ /tmp/sync_backup/

# Run sync again without changes: notice 0 bytes transferred!
rsync -av --stats /tmp/sync_source/ /tmp/sync_backup/

# Modify only one file and add a new one
echo "Updated file 1" >> /tmp/sync_source/file1.txt
echo "File 3" > /tmp/sync_source/file3.txt

# Third sync: copies ONLY what changed
rsync -av --stats /tmp/sync_source/ /tmp/sync_backup/
```

### Drill 6: Automated Nightly Backup Script Execution (`d22-backup-plan`)
```bash
# Run the automated backup manager script with a 7-day retention policy
./backup_manager.sh /tmp/sync_source /tmp/backup_store 7

# Inspect created archive and directory structure
ls -lh /tmp/backup_store
```

---

## 🚨 Incident & Troubleshooting Journal (Post-Mortem)

### Case Study: The Trailing Slash Disaster (`rsync --delete`)
- **Symptom**: During a scheduled midnight deployment sync, an engineer noticed that `/var/www/html/` on the production web server was completely wiped clean, resulting in an immediate HTTP 403 Forbidden outage.
- **Root Cause**:
  The engineer intended to sync new release artifacts into the web root:
  ```bash
  # Intended:
  rsync -av --delete /releases/v2.1/ /var/www/html/
  
  # Accidental execution:
  rsync -av --delete /empty_staging /var/www/html
  ```
  Missing the trailing slash and passing an uninitialized or empty staging directory combined with `--delete` instructed `rsync` to make `/var/www/html` match `/empty_staging`, immediately wiping all production website assets.
- **Recovery**:
  The SRE team restored the static assets from the latest timestamped `.tar.gz` backup created by the nightly backup daemon, restoring service within 12 minutes.
- **Prevention Rules**:
  1. **Always dry-run first**: When testing any `rsync` command involving `--delete`, execute with `--dry-run` first.
  2. **Explicit Trailing Slash Convention**: Explicitly document and script directory paths using strict path normalization.
  3. **Safety Guard Clauses**: Verify source directories are non-empty (`[ $(ls -A "$SRC" | wc -l) -gt 0 ]`) before invoking sync pipelines.
