# The Unix Permissions Matrix Architecture

```text
- r w x r - x r - -
┬ └───┬───┘ └───┬───┘ └───┬───┘
│     │         │         └── Others (World) Permissions: r-- (Read Only)
│     │         └─────────── Group Permissions: r-x (Read & Execute)
│     └───────────────────── User (Owner) Permissions: rwx (Read, Write & Execute)
└─────────────────────────── File Type: - (Regular File), d (Directory), l (Symlink)
```

---

## 🧮 Octal Values
- **Read (`r`)** = `4` (Binary `100`)
- **Write (`w`)** = `2` (Binary `010`)
- **Execute (`x`)** = `1` (Binary `001`)

```text
r w x  = 4 + 2 + 1 = 7
r - x  = 4 + 0 + 1 = 5
r - -  = 4 + 0 + 0 = 4
- - -  = 0 + 0 + 0 = 0
```

---

## 📁 Files vs. Directories: The Crucial Difference

| Permission | Effect on a Regular File | Effect on a Directory |
|:---:|---|---|
| **`r` (Read)** | View/read contents of file (`cat`, `less`). | List files inside directory (`ls`). |
| **`w` (Write)** | Modify or overwrite file content. | Create, delete, or rename files inside directory. |
| **`x` (Execute)**| Run file as a binary program or script. | **Traverse/Enter** the directory (`cd`) or access inodes inside. |

> [!IMPORTANT]
> If a directory has `r` but lacks `x`, you can list the names of files inside, but you **cannot `cd` into it** or read any file contents!

---

## 🔒 Standard Production Presets
- Private keys (`id_rsa`, `.env`): `chmod 600` (`-rw-------`)
- Regular web / config files: `chmod 644` (`-rw-r--r--`)
- Executable scripts / binaries: `chmod 755` (`-rwxr-xr-x`)
- Secure directories: `chmod 700` (`drwx------`)


---

## 🚨 Incident & Troubleshooting Journal (Lab Post-Mortem)

### Case Study: Directory Traversal Lockout Despite Full Read Access
- **Symptom / Alert**: A web application could not read static assets located inside `/var/www/assets/`, logging `Permission denied`.
- **Investigation & Triage**:
  1. Inspected directory permissions: `ls -ld /var/www/assets/`.
  2. Output was `drw-r--r-- 2 www-data www-data` (mode `0644`).
  3. Attempted to enter folder: `cd /var/www/assets` -> `bash: cd: /var/www/assets: Permission denied`.
- **Root Cause Analysis (RCA)**: On Linux directories, the Read (`r`) bit only permits reading the list of filenames inside the folder. The Execute (`x`) bit is required to **traverse/enter** the directory and read inode metadata of the files inside.
- **Remediation & Fix**:
  - Restored execute bit on the directory: `chmod 755 /var/www/assets/`.
  - Web application resumed normal asset serving.
- **Engineering Takeaway**: Never apply generic file permissions (`644`) recursively to directories. Standard directory permission baseline is `755` (or `750` for restricted access).
